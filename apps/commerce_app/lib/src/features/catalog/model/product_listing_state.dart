import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/serde.dart';

part 'product_listing_state.g.dart';

/// Lifecycle of a source-shaped product listing route.
enum ProductListingStatus {
  /// No route has requested data yet.
  idle,

  /// Taxonomy and products are being resolved.
  loading,

  /// The requested listing is ready, including a valid empty result.
  ready,

  /// The collection or category handle does not exist.
  missing,

  /// A dependency failed without exposing its internal error to the customer.
  failed,
}

/// Complete render state for store, collection, and category listings.
@Derive([ToString(), Eq(), CopyWith()])
final class ProductListingState with _$ProductListingState {
  /// Creates an immutable listing state.
  const ProductListingState({
    this.status = ProductListingStatus.idle,
    this.requestKey = '',
    this.title = '',
    this.description = '',
    this.parents = const [],
    this.children = const [],
    this.products = const [],
    this.sortBy = 'created_at',
    this.currentPage = 1,
    this.totalPages = 0,
    this.currencyCode = 'usd',
  });

  /// Direct child categories shown above a category's product grid.
  final List<ProductCategory> children;

  /// One-based page rendered by this state.
  final int currentPage;

  /// Currency used for product prices.
  final String currencyCode;

  /// Customer-facing category copy, empty when the source has none.
  final String description;

  /// Root-to-leaf ancestors rendered as category breadcrumbs.
  final List<ProductCategory> parents;

  /// Products on the requested page.
  final List<Product> products;

  /// Identifies the route/query combination that owns this state.
  final String requestKey;

  /// Medusa-compatible sort query value.
  final String sortBy;

  /// Current request lifecycle.
  final ProductListingStatus status;

  /// Customer-facing collection/category/store title.
  final String title;

  /// Number of pages available at the source limit of twelve.
  final int totalPages;

  /// Whether a completed listing contains no products.
  bool get isEmpty => status == ProductListingStatus.ready && products.isEmpty;
}
