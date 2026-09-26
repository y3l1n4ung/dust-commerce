part of 'product_listing_view_model.dart';

final class _ListingMeta {
  const _ListingMeta({
    required this.requestKey,
    required this.title,
    required this.page,
    required this.sortBy,
    this.description = '',
    this.parents = const [],
    this.children = const [],
    this.categoryFilters = const [],
    this.optionFilters = const [],
    this.selectedCategoryHandles = const [],
    this.selectedOptionValueIds = const [],
    this.searchQuery = '',
    this.collection = const None(),
    this.category = const None(),
    this.currencyCode = 'usd',
  });

  final Option<String> category;
  final List<ProductCategoryFilter> categoryFilters;
  final List<ProductCategory> children;
  final Option<String> collection;
  final String currencyCode;
  final String description;
  final List<ProductOptionFilterView> optionFilters;
  final int page;
  final List<ProductCategory> parents;
  final String requestKey;
  final String searchQuery;
  final List<String> selectedCategoryHandles;
  final List<String> selectedOptionValueIds;
  final String sortBy;
  final String title;

  _ListingMeta copyWith({
    String? title,
    String? description,
    List<ProductCategory>? parents,
    List<ProductCategory>? children,
    List<ProductCategoryFilter>? categoryFilters,
    List<ProductOptionFilterView>? optionFilters,
  }) =>
      _ListingMeta(
        requestKey: requestKey,
        title: title ?? this.title,
        description: description ?? this.description,
        page: page,
        sortBy: sortBy,
        parents: parents ?? this.parents,
        children: children ?? this.children,
        categoryFilters: categoryFilters ?? this.categoryFilters,
        optionFilters: optionFilters ?? this.optionFilters,
        selectedCategoryHandles: selectedCategoryHandles,
        selectedOptionValueIds: selectedOptionValueIds,
        searchQuery: searchQuery,
        collection: collection,
        category: category,
        currencyCode: currencyCode,
      );

  ProductListingState toState({
    required ProductListingStatus status,
    List<Product> products = const [],
    int totalPages = 0,
  }) =>
      ProductListingState(
        status: status,
        requestKey: requestKey,
        title: title,
        description: description,
        parents: parents,
        children: children,
        categoryFilters: categoryFilters,
        optionFilters: optionFilters,
        selectedCategoryHandles: selectedCategoryHandles,
        selectedOptionValueIds: selectedOptionValueIds,
        searchQuery: searchQuery,
        products: products,
        sortBy: sortBy,
        currentPage: page,
        totalPages: totalPages,
        currencyCode: currencyCode,
      );
}
