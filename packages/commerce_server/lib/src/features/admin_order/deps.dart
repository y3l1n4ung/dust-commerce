import 'package:commerce_server/src/features/admin_order/repository.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// Persistence required only by merchant order routes.
final class AdminOrderDeps {
  /// Creates the focused order dependency bundle.
  const AdminOrderDeps({required this.orders});

  /// Protected order-list reads.
  final AdminOrderRepository orders;
}

/// Extracts attached order dependencies or returns a configuration failure.
Future<Result<AdminOrderDeps, Rejection>> adminOrderDeps(Request request) =>
    stateOf<AdminOrderDeps>(request);
