import 'package:commerce_server/src/features/admin_customer_group/list_repository.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// Persistence required only by merchant customer-group routes.
final class AdminCustomerGroupDeps {
  /// Creates the focused group dependency bundle.
  const AdminCustomerGroupDeps({required this.groups});

  /// Protected customer-group list reads.
  final AdminCustomerGroupListRepository groups;
}

/// Extracts attached customer-group dependencies or a configuration failure.
Future<Result<AdminCustomerGroupDeps, Rejection>> adminCustomerGroupDeps(
  Request request,
) =>
    stateOf<AdminCustomerGroupDeps>(request);
