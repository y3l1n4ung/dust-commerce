import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/account/crypto.dart';
import 'package:commerce_server/src/features/admin/deps.dart';
import 'package:commerce_server/src/features/admin/service/service.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_server/server.dart';

const ValidatedExtractable<AdminCredentials> _credentialsBody =
    ValidatedExtractable(
  JsonExtractable<AdminCredentials>(AdminCredentials.fromJson),
);

/// `POST /auth/admin/emailpass` — exchange admin credentials for a token.
Future<Result<AdminIssuedToken, Rejection>> adminSignInHandler(
  Request request,
) async {
  final decoded = await _credentialsBody.extract(request);
  if (decoded case Err(:final error)) return Err(error);
  final depsResult = await adminDeps(request);
  if (depsResult case Err(:final error)) return Err(error);
  final deps = (depsResult as Ok<AdminDeps, Rejection>).value;

  late final Result<Option<AdminIssuedToken>, SqlxError> result;
  try {
    result = await adminSignIn(
      deps.reads,
      deps.writes,
      (decoded as Ok<AdminCredentials, Rejection>).value,
      now: deps.clock.now(),
      dummyPasswordHash: deps.dummyPasswordHash,
      passwordWork: deps.passwordWork,
    );
  } on PasswordCapacityException {
    return const Err(
      Rejection.status(429, 'Authentication is busy; retry shortly'),
    );
  }
  return switch (result) {
    Ok(value: Some(value: final token)) => Ok(token),
    Ok(value: None()) =>
      const Err(Rejection.unauthorized('Invalid email or password')),
    Err() => const Err(Rejection.internal()),
  };
}
