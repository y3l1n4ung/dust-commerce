import 'dart:convert';

import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/account/crypto.dart';
import 'package:commerce_server/src/features/admin/model.dart';
import 'package:commerce_server/src/features/admin/repository/repository.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:commerce_server/src/infra/option.dart';
import 'package:dust_dart/db.dart';

/// Why an administrator was not bootstrapped.
enum AdminBootstrapFailure {
  /// An active administrator already owns the normalized email.
  alreadyExists,
}

/// Creates an admin profile and provider identity in one transaction.
Future<Result<Result<AdminUserResponse, AdminBootstrapFailure>, SqlxError>>
    bootstrapAdmin(
  CommerceDatabase database,
  AdminCredentials credentials, {
  required String Function() nextId,
  required PasswordWorkLimiter passwordWork,
  String? firstName,
  String? lastName,
}) async {
  final email = credentials.email.trim().toLowerCase();
  final passwordHash = await Passwords.hash(
    credentials.password,
    limiter: passwordWork,
  );
  final userId = nextId();
  final authIdentityId = nextId();
  final providerIdentityId = nextId();

  return database.transaction((tx) async {
    final writes = AdminCreateRepository(tx);
    final inserted = await writes.insertAdmin(
      userId,
      email,
      firstName,
      lastName,
    );
    if (inserted case Err(:final error)) return Err(error);
    final user = optionOf(
      (inserted as Ok<AdminUserResponse?, SqlxError>).value,
    );
    if (user case None()) {
      return const Ok(Err(AdminBootstrapFailure.alreadyExists));
    }

    final identity = await writes.insertAuthIdentity(
      authIdentityId,
      jsonEncode({'admin_user_id': userId}),
    );
    if (identity case Err(:final error)) return Err(error);
    final provider = await writes.insertProviderIdentity(
      providerIdentityId,
      email,
      authIdentityId,
      jsonEncode({'password': passwordHash}),
    );
    if (provider case Err(:final error)) return Err(error);

    return Ok(Ok((user as Some<AdminUserResponse>).value));
  });
}

/// Exchanges valid admin credentials for a short-lived opaque token.
Future<Result<Option<AdminIssuedToken>, SqlxError>> adminSignIn(
  AdminReadRepository reads,
  AdminCreateRepository writes,
  AdminCredentials input, {
  required DateTime now,
  required Future<String> dummyPasswordHash,
  required PasswordWorkLimiter passwordWork,
  Duration lifetime = const Duration(days: 7),
}) async {
  final found = await reads.adminByEmail(input.email.trim().toLowerCase());
  if (found case Err(:final error)) return Err(error);
  final account = optionOf(
    (found as Ok<AdminPasswordCredential?, SqlxError>).value,
  );
  final expected = switch (account) {
    Some(value: final credential) => credential.passwordHash,
    None() => await dummyPasswordHash,
  };
  final valid = await Passwords.verify(
    input.password,
    expected,
    limiter: passwordWork,
  );
  if (account case None()) return const Ok(None<AdminIssuedToken>());
  if (!valid) return const Ok(None<AdminIssuedToken>());

  final credential = (account as Some<AdminPasswordCredential>).value;
  final token = Tokens.issue();
  final expiresAt = now.toUtc().add(lifetime);
  final stored = await writes.insertToken(
    await Tokens.fingerprint(token),
    credential.authIdentityId,
    expiresAt.toIso8601String(),
  );
  if (stored case Err(:final error)) return Err(error);
  return Ok(Some(AdminIssuedToken(token: token, expiresAt: expiresAt)));
}
