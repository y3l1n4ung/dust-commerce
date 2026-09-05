import 'package:commerce_server/src/features/account/crypto.dart';
import 'package:commerce_server/src/features/account/deps.dart';
import 'package:commerce_server/src/features/account/model.dart';
import 'package:commerce_server/src/features/account/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_server/server.dart';

const ValidatedExtractable<RegisterAccountBody> _registerBody =
    ValidatedExtractable(
  JsonExtractable<RegisterAccountBody>(RegisterAccountBody.fromJson),
);
const ValidatedExtractable<Credentials> _credentialsBody = ValidatedExtractable(
  JsonExtractable<Credentials>(Credentials.fromJson),
);

/// `POST /store/customers` — create a customer account.
Future<Result<CustomerResponse, Rejection>> registerAccountHandler(
  Request request,
) async {
  final decoded = await _registerBody.extract(request);
  if (decoded case Err(:final error)) return Err(error);
  final depsResult = await accountDeps(request);
  if (depsResult case Err(:final error)) return Err(error);
  final deps = (depsResult as Ok<AccountDeps, Rejection>).value;

  late final Result<Result<CustomerResponse, RegisterFailure>, SqlxError>
      result;
  try {
    result = await registerAccount(
      deps.database,
      (decoded as Ok<RegisterAccountBody, Rejection>).value,
      nextId: deps.clock.nextId,
      passwordWork: deps.passwordWork,
    );
  } on PasswordCapacityException {
    return const Err(
      Rejection.status(429, 'Authentication is busy; retry shortly'),
    );
  }
  return switch (result) {
    Ok(value: Ok(value: final customer)) => Ok(customer),
    Ok(value: Err(error: RegisterFailure.alreadyExists)) =>
      const Err(Rejection.conflict('A customer account already exists')),
    Err() => const Err(Rejection.internal()),
  };
}

/// `POST /auth/customer/emailpass` — exchange credentials for a token.
Future<Result<IssuedToken, Rejection>> signInHandler(Request request) async {
  final decoded = await _credentialsBody.extract(request);
  if (decoded case Err(:final error)) return Err(error);
  final depsResult = await accountDeps(request);
  if (depsResult case Err(:final error)) return Err(error);
  final deps = (depsResult as Ok<AccountDeps, Rejection>).value;

  late final Result<Option<IssuedToken>, SqlxError> result;
  try {
    result = await signIn(
      deps.reads,
      deps.writes,
      (decoded as Ok<Credentials, Rejection>).value,
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
