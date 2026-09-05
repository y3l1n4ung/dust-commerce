import 'package:commerce_server/src/features/account/deps.dart';
import 'package:commerce_server/src/features/account/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// `GET /store/customers/me` — return the authenticated customer.
Future<Result<Customer, Rejection>> readCurrentCustomerHandler(
  Request request,
) async {
  final bearer = await const BearerTokenExtractable().extract(request);
  if (bearer case Err(:final error)) return Err(error);
  final depsResult = await accountDeps(request);
  if (depsResult case Err(:final error)) return Err(error);
  final deps = (depsResult as Ok<AccountDeps, Rejection>).value;

  final found = await authenticateToken(
    deps.reads,
    (bearer as Ok<String, Rejection>).value,
    deps.clock.now(),
  );
  return switch (found) {
    Ok(value: final row?) => Ok(row.customer),
    Ok() => const Err(Rejection.unauthorized('Invalid or expired token')),
    Err() => const Err(Rejection.internal()),
  };
}
