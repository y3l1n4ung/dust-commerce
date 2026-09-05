import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/serde.dart';

part 'product_state.g.dart';

/// The product request currently visible to the detail route.
enum ProductDetailStatus {
  /// No product request has started.
  idle,

  /// A product request is in flight.
  loading,

  /// The product is ready to render.
  ready,

  /// The product request failed.
  failed,
}

/// Product data and the option values selected by the customer.
@Derive([ToString(), Eq(), CopyWith()])
class ProductDetailState with _$ProductDetailState {
  /// Creates product detail state.
  const ProductDetailState({
    this.status = ProductDetailStatus.idle,
    this.selection = const {},
    this.product,
    this.message,
  });

  /// A display-safe request failure.
  final String? message;

  /// The product returned by the server.
  final Product? product;

  /// Selected value keyed by product-option id.
  final Map<String, String> selection;

  /// The request lifecycle.
  final ProductDetailStatus status;

  /// The exact purchasable variant selected by all required options.
  ProductVariant? get selectedVariant {
    final current = product;
    if (current == null || current.variants.isEmpty) return null;
    if (current.variants.length == 1) return current.variants.single;
    if (selection.length != current.options.length) return null;
    return current.variantFor(selection);
  }
}
