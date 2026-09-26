part of 'product_listing_view_model.dart';

extension on ProductListingViewModel {
  int _begin(_ListingMeta meta) {
    final revision = ++_revision;
    _setState(meta.toState(status: ProductListingStatus.loading));
    return revision;
  }

  bool _active(int revision) => revision == _revision;

  void _missing(_ListingMeta meta) =>
      _setState(meta.toState(status: ProductListingStatus.missing));

  void _fail(_ListingMeta meta, int revision) {
    if (!_active(revision)) return;
    _setState(meta.toState(status: ProductListingStatus.failed));
  }
}

List<Product> _sorted(
  List<Product> products,
  String sortBy,
  String currencyCode,
) {
  final sorted = products.toList(growable: false);
  if (sortBy == 'created_at' || sortBy == 'relevance') return sorted;
  sorted.sort((left, right) {
    if (sortBy == 'title_asc') return left.title.compareTo(right.title);
    if (sortBy == 'title_desc') return right.title.compareTo(left.title);
    final leftPrice = left.cheapestIn(currencyCode)?.amount;
    final rightPrice = right.cheapestIn(currencyCode)?.amount;
    if (leftPrice == null) return rightPrice == null ? 0 : 1;
    if (rightPrice == null) return -1;
    return sortBy == 'price_desc'
        ? rightPrice.compareTo(leftPrice)
        : leftPrice.compareTo(rightPrice);
  });
  return sorted;
}

List<ProductCategory> _parentsOf(
  ProductCategory category,
  List<ProductCategory> categories,
) {
  final byId = {for (final item in categories) item.id: item};
  final seen = <String>{category.id};
  final parents = <ProductCategory>[];
  var parentId = category.parentId;
  while (parentId != null && seen.add(parentId)) {
    final parent = byId[parentId];
    if (parent == null) break;
    parents.add(parent);
    parentId = parent.parentId;
  }
  return parents.reversed.toList(growable: false);
}
