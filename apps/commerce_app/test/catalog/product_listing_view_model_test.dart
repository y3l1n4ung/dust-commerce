import 'dart:io';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_server/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/support.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient server;
  late ProductListingViewModel viewModel;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('commerce_listing');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await seedRoundTripCatalog(database);
    await _seedPage(database);
    server = await TestClient.serve(buildApp(database));
    viewModel = ProductListingViewModel(
      ProductListingViewModelArgs(
        api: CommerceApi(Dio(), baseUrl: server.origin),
      ),
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('collection route resolves metadata, filters, and pages by twelve',
      () async {
    await viewModel.loadCollection('summer');

    expect(viewModel.state.status, ProductListingStatus.ready);
    expect(viewModel.state.title, 'Summer');
    expect(viewModel.state.products, hasLength(12));
    expect(viewModel.state.totalPages, 2);

    await viewModel.loadCollection('summer', page: 2);
    expect(viewModel.state.products, hasLength(2));
    expect(viewModel.state.currentPage, 2);
  });

  test('category route reconstructs parents and direct children', () async {
    await viewModel.loadCategory('clothing/shirts');

    expect(viewModel.state.title, 'Shirts');
    expect(viewModel.state.parents.map((it) => it.name), ['Clothing']);
    expect(viewModel.state.products, hasLength(12));

    await viewModel.loadCategory('clothing');
    expect(viewModel.state.children.map((it) => it.name), ['Shirts']);
  });

  test('price choices sort in the requested currency', () async {
    await viewModel.loadCollection('summer', sortBy: 'price_asc');
    expect(
      viewModel.state.products.first.cheapestIn('usd')?.amount,
      100,
    );

    await viewModel.loadCollection('summer', sortBy: 'price_desc');
    expect(
      viewModel.state.products.first.cheapestIn('usd')?.amount,
      1999,
    );
  });

  test('currency is part of the listing request identity', () async {
    await viewModel.loadCollection('summer');
    final usdKey = viewModel.state.requestKey;

    await viewModel.loadCollection('summer', currency: 'eur');

    expect(viewModel.state.currencyCode, 'eur');
    expect(viewModel.state.requestKey, isNot(usdKey));
    expect(viewModel.state.products, hasLength(1));
    expect(viewModel.state.products.single.cheapestIn('eur'), isNotNull);
  });

  test('store exposes stable options and filters by selected values', () async {
    await viewModel.loadStore(optionValueIds: const ['optval_small']);

    expect(viewModel.state.status, ProductListingStatus.ready);
    expect(viewModel.state.selectedOptionValueIds, ['optval_small']);
    expect(viewModel.state.optionFilters.single.id, 'opt_size');
    expect(viewModel.state.products.map((product) => product.handle), [
      't-shirt',
    ]);
  });

  test('option discovery failure does not take down products', () async {
    final resilient = ProductListingViewModel(
      ProductListingViewModelArgs(api: _OptionFailureApi(viewModel.args.api)),
    );
    addTearDown(resilient.dispose);

    await resilient.loadStore();

    expect(resilient.state.status, ProductListingStatus.ready);
    expect(resilient.state.products, isNotEmpty);
    expect(resilient.state.optionFilters, isEmpty);
  });

  test('unknown taxonomy becomes missing without exposing an exception',
      () async {
    await viewModel.loadCollection('unknown');
    expect(viewModel.state.status, ProductListingStatus.missing);

    await viewModel.loadCategory('unknown');
    expect(viewModel.state.status, ProductListingStatus.missing);
  });
}

final class _OptionFailureApi implements CommerceApi {
  const _OptionFailureApi(this.delegate);

  final CommerceApi delegate;

  @override
  Future<ProductOptionFilterListView> productOptions({
    int? limit,
    int? offset,
  }) =>
      Future.error(StateError('option discovery unavailable'));

  @override
  Future<ProductPageView> products({
    String? currency,
    String? collection,
    String? category,
    String? tag,
    List<String> optionValueIds = const [],
    int? limit,
    int? offset,
  }) =>
      delegate.products(
        currency: currency,
        collection: collection,
        category: category,
        tag: tag,
        optionValueIds: optionValueIds,
        limit: limit,
        offset: offset,
      );

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unused API method');
}

Future<void> _seedPage(CommerceDatabase database) async {
  for (var index = 1; index <= 13; index++) {
    final suffix = index.toString().padLeft(2, '0');
    await queryExecute(
      'INSERT INTO products '
      '(id, collection_id, title, handle, status) VALUES (?, ?, ?, ?, ?)',
      [
        'prod_$suffix',
        'col_summer',
        'Product $suffix',
        'product-$suffix',
        'published',
      ],
    ).execute(database.executor);
    await queryExecute(
      'INSERT INTO product_variants '
      '(id, product_id, title, inventory_quantity) VALUES (?, ?, ?, ?)',
      ['var_$suffix', 'prod_$suffix', 'Default', 10],
    ).execute(database.executor);
    await queryExecute(
      'INSERT INTO variant_prices '
      '(variant_id, currency_code, amount) VALUES (?, ?, ?)',
      ['var_$suffix', 'usd', index * 100],
    ).execute(database.executor);
    await queryExecute(
      'INSERT INTO product_category_products '
      '(product_id, category_id) VALUES (?, ?)',
      ['prod_$suffix', 'cat_shirts'],
    ).execute(database.executor);
  }
}
