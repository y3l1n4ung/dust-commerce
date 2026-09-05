import 'package:commerce_server/src/features/account/deps.dart';
import 'package:commerce_server/src/features/account/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

/// The customer identity proven by a bearer token.
///
/// This contains the raw token only so sign-out can revoke it. It deliberately
/// derives no serializer or string representation.
final class AuthenticatedCustomer {
  /// Creates an authenticated request identity.
  const AuthenticatedCustomer({required this.customer, required this.token});

  /// The store customer making the request.
  final Customer customer;

  /// The bearer token proven by this extraction.
  final String token;
}

/// Axum-style required authentication extracted from request parts.
final class CustomerAuth implements FromRequestParts<AuthenticatedCustomer> {
  /// Creates the stateless extractor.
  const CustomerAuth();

  @override
  Future<Result<AuthenticatedCustomer, Rejection>> extract(
    Request request,
  ) async {
    final state = await const StateExtractable<AccountDeps>().extract(request);
    if (state case Err(:final error)) return Err(error);

    final bearer = await const BearerTokenExtractable().extract(request);
    if (bearer case Err(:final error)) return Err(error);
    final token = (bearer as Ok<String, Rejection>).value;
    final deps = (state as Ok<AccountDeps, Rejection>).value;

    return switch (
        await authenticateToken(deps.reads, token, deps.clock.now())) {
      Ok(value: final row?) =>
        Ok(AuthenticatedCustomer(customer: row.customer, token: token)),
      Ok() => const Err(Rejection.unauthorized(
          'Invalid or expired token',
          challenge: 'Bearer',
        )),
      Err() => const Err(Rejection.internal()),
    };
  }
}

/// Optional authentication where only a missing header becomes a guest.
final class OptionalCustomerAuth
    implements FromRequestParts<AuthenticatedCustomer?> {
  /// Creates the stateless extractor.
  const OptionalCustomerAuth();

  @override
  Future<Result<AuthenticatedCustomer?, Rejection>> extract(
    Request request,
  ) async {
    if (Authorization.of(request) == null) return const Ok(null);
    return const CustomerAuth().extract(request);
  }
}
