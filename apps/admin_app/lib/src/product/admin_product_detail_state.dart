import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/serde.dart';

part 'admin_product_detail_state.g.dart';

/// Lifecycle of one merchant product detail request.
enum AdminProductDetailStatus {
  /// No detail request has started.
  idle,

  /// A product detail is loading.
  loading,

  /// The requested detail is ready.
  ready,

  /// The request failed with display-safe copy.
  failed,
}

/// Immutable state for the authenticated product detail route.
@Derive([ToString(), Eq(), CopyWith()])
final class AdminProductDetailState with _$AdminProductDetailState {
  /// Creates detail state without transport objects in the widget tree.
  const AdminProductDetailState({
    this.status = AdminProductDetailStatus.idle,
    this.product = const None(),
    this.failure = const None(),
  });

  /// Display-safe failure copy.
  final Option<String> failure;

  /// Explicit admin product allowlist when loaded.
  final Option<AdminProductDetail> product;

  /// Current request lifecycle.
  final AdminProductDetailStatus status;
}
