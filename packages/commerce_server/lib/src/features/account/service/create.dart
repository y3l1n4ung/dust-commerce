import 'dart:convert';

import 'package:commerce_server/src/features/account/crypto.dart';
import 'package:commerce_server/src/features/account/model.dart';
import 'package:commerce_server/src/features/account/repository/repository.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Why a customer account was not created.
enum RegisterFailure {
  /// An active account already owns this email address.
  alreadyExists,
}

/// Creates a customer, auth identity, and email provider atomically.
Future<Result<(Customer?, RegisterFailure?), SqlxError>> registerAccount(
  CommerceDatabase database,
  RegisterAccountBody input, {
  required String Function() nextId,
  required PasswordWorkLimiter passwordWork,
}) async {
  final email = input.email.trim().toLowerCase();
  final passwordHash = await Passwords.hash(
    input.password,
    limiter: passwordWork,
  );
  final customerId = nextId();
  final authIdentityId = nextId();
  final providerIdentityId = nextId();

  return database.transaction((tx) async {
    final writes = AccountCreateRepository(tx);
    final customer = await writes.insertCustomer(
      customerId,
      email,
      input.firstName,
      input.lastName,
      input.phone,
    );
    if (customer case Err(:final error)) return Err(error);
    if ((customer as Ok<ExecResult, SqlxError>).value.rowsAffected == 0) {
      return const Ok((null, RegisterFailure.alreadyExists));
    }

    final identity = await writes.insertAuthIdentity(
      authIdentityId,
      jsonEncode({'customer_id': customerId}),
    );
    if (identity case Err(:final error)) return Err(error);

    final provider = await writes.insertProviderIdentity(
      providerIdentityId,
      email,
      authIdentityId,
      jsonEncode({'password': passwordHash}),
    );
    if (provider case Err(:final error)) return Err(error);

    return Ok((
      Customer(
        id: customerId,
        email: email,
        firstName: input.firstName,
        lastName: input.lastName,
        phone: input.phone,
      ),
      null,
    ));
  });
}

/// Exchanges valid credentials for a short-lived opaque token.
Future<Result<(IssuedToken?, bool invalid), SqlxError>> signIn(
  AccountReadRepository reads,
  AccountCreateRepository writes,
  Credentials input, {
  required DateTime now,
  required Future<String> dummyPasswordHash,
  required PasswordWorkLimiter passwordWork,
  Duration lifetime = const Duration(days: 7),
}) async {
  final found = await reads.accountByEmail(input.email.trim().toLowerCase());
  if (found case Err(:final error)) return Err(error);

  final account = (found as Ok<AccountRow?, SqlxError>).value;
  final expected = account?.passwordHash ?? await dummyPasswordHash;
  final valid = await Passwords.verify(
    input.password,
    expected,
    limiter: passwordWork,
  );
  if (account == null || !valid) return const Ok((null, true));

  final token = Tokens.issue();
  final expiresAt = now.toUtc().add(lifetime).toIso8601String();
  final stored = await writes.insertToken(
    await Tokens.fingerprint(token),
    account.authIdentityId,
    expiresAt,
  );
  if (stored case Err(:final error)) return Err(error);

  return Ok((IssuedToken(token: token, expiresAt: expiresAt), false));
}
