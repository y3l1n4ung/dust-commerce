import 'package:commerce_server/src/features/admin_customer/repository.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// Persistence required only by merchant customer routes.
final class AdminCustomerDeps {
  /// Creates the focused customer dependency bundle.
  const AdminCustomerDeps({required this.customers});

  /// Protected customer-list reads.
  final AdminCustomerRepository customers;
}

/// Extracts attached customer dependencies or a configuration failure.
Future<Result<AdminCustomerDeps, Rejection>> adminCustomerDeps(
  Request request,
) =>
    stateOf<AdminCustomerDeps>(request);
