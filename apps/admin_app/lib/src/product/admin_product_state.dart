import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/serde.dart';

part 'admin_product_state.g.dart';

/// Lifecycle of the authenticated merchant catalogue.
enum AdminProductStatus {
  /// No catalogue request has started.
  idle,

  /// A catalogue request is active.
  loading,

  /// The current catalogue page is ready.
  ready,

  /// The request failed with a display-safe message.
  failed,
}

/// Immutable state for Medusa-shaped product administration.
@Derive([ToString(), Eq(), CopyWith()])
final class AdminProductState with _$AdminProductState {
  /// Creates catalogue state without leaking transport objects into the UI.
  const AdminProductState({
    this.status = AdminProductStatus.idle,
    this.products = const [],
    this.count = 0,
    this.limit = 20,
    this.offset = 0,
    this.query = '',
    this.failure = const None(),
  });

  /// Total rows matching [query].
  final int count;

  /// Display-safe failure message.
  final Option<String> failure;

  /// Server-owned page size.
  final int limit;

  /// Number of matching rows skipped.
  final int offset;

  /// Current allowlisted catalogue rows.
  final List<AdminProduct> products;

  /// Normalized title-or-handle search.
  final String query;

  /// Current request lifecycle.
  final AdminProductStatus status;

  /// Whether another page exists after this one.
  bool get hasNext => offset + products.length < count;

  /// Whether a previous page exists.
  bool get hasPrevious => offset > 0;
}
