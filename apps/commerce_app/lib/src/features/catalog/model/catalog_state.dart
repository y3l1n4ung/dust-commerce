import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/serde.dart';

part 'catalog_state.g.dart';

/// Where the catalogue screen is in its loading lifecycle.
enum CatalogStatus {
  /// Nothing fetched yet.
  idle,

  /// A request is in flight.
  loading,

  /// Products arrived.
  ready,

  /// The request failed.
  failed,
}

/// Everything the catalogue screen renders.
///
/// The screen holds no state of its own. A widget that keeps something across
/// a frame is a second source of truth, and the two drift.
@Derive([ToString(), Eq(), CopyWith()])
class CatalogState with _$CatalogState {
  /// Creates a [CatalogState].
  const CatalogState({
    this.status = CatalogStatus.idle,
    this.products = const [],
    this.total = 0,
    this.currencyCode = 'usd',
    this.message,
  });

  /// The currency prices are shown in.
  final String currencyCode;

  /// Why the last request failed, when it did.
  final String? message;

  /// The products on the current page.
  final List<Product> products;

  /// Where the screen is in its lifecycle.
  final CatalogStatus status;

  /// How many published products exist.
  final int total;

  /// Whether the screen has nothing to show and is not waiting.
  bool get isEmpty => products.isEmpty && status == CatalogStatus.ready;

  /// Whether a spinner belongs on screen.
  bool get isLoading => status == CatalogStatus.loading;
}
