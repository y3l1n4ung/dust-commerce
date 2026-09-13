import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/serde.dart';

part 'admin_order_detail_state.g.dart';

/// Lifecycle of one protected Admin order-detail request.
enum AdminOrderDetailStatus {
  /// No detail request has started.
  idle,

  /// The selected order is loading.
  loading,

  /// The complete order snapshot is ready.
  ready,

  /// The request failed with display-safe copy.
  failed,
}

/// Immutable state for one merchant order-detail route.
@Derive([ToString(), Eq(), CopyWith()])
final class AdminOrderDetailState with _$AdminOrderDetailState {
  /// Creates detail state without transport or Dio objects in widgets.
  const AdminOrderDetailState({
    this.status = AdminOrderDetailStatus.idle,
    this.order = const None(),
    this.failure = const None(),
  });

  /// Display-safe failure copy.
  final Option<String> failure;

  /// Explicit merchant order allowlist when loaded.
  final Option<AdminOrderDetail> order;

  /// Current request lifecycle.
  final AdminOrderDetailStatus status;
}
