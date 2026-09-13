import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/serde.dart';

part 'admin_order_state.g.dart';

/// Lifecycle of the authenticated merchant order list.
enum AdminOrderListStatus {
  /// No order request has started.
  idle,

  /// An order request is active.
  loading,

  /// The current order page is ready.
  ready,

  /// The request failed with a display-safe message.
  failed,
}

/// Immutable state for the Medusa-shaped order table.
@Derive([ToString(), Eq(), CopyWith()])
final class AdminOrderState with _$AdminOrderState {
  /// Creates order-list state without transport objects.
  const AdminOrderState({
    this.status = AdminOrderListStatus.idle,
    this.orders = const [],
    this.count = 0,
    this.limit = 20,
    this.offset = 0,
    this.query = '',
    this.statuses = const [],
    this.regionIds = const [],
    this.createdAt = const AdminDateFilter(),
    this.updatedAt = const AdminDateFilter(),
    this.order = AdminOrderOrder.createdAtDesc,
    this.failure = const None(),
  });

  /// Total rows matching the active query.
  final int count;

  /// Creation-time comparison applied by the server.
  final AdminDateFilter createdAt;

  /// Display-safe request failure.
  final Option<String> failure;

  /// Server-owned page size.
  final int limit;

  /// Number of matching rows skipped.
  final int offset;

  /// Stable allowlisted server ordering.
  final AdminOrderOrder order;

  /// Explicit merchant order summaries.
  final List<AdminOrder> orders;

  /// Normalized display-id, customer, or email search.
  final String query;

  /// Selected selling-region identifiers.
  final List<String> regionIds;

  /// Current request lifecycle.
  final AdminOrderListStatus status;

  /// Selected order lifecycle states.
  final List<AdminOrderStatus> statuses;

  /// Update-time comparison applied by the server.
  final AdminDateFilter updatedAt;

  /// Whether another server-owned page exists.
  bool get hasNext => offset + orders.length < count;

  /// Whether a preceding server-owned page exists.
  bool get hasPrevious => offset > 0;

  /// Whether any filter other than search and ordering is active.
  bool get hasFilters =>
      statuses.isNotEmpty ||
      regionIds.isNotEmpty ||
      !createdAt.isEmpty ||
      !updatedAt.isEmpty;
}
