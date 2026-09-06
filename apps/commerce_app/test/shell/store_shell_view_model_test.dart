import 'dart:io';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_server/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient server;
  late CommerceApi api;
  late _MemoryCountryPreferenceStore countries;
  late StoreShellViewModel viewModel;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('commerce_shell');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await seedDevelopmentStore(database);
    server = await TestClient.serve(buildApp(database));
    api = CommerceApi(Dio(), baseUrl: server.origin);
    countries = _MemoryCountryPreferenceStore();
    viewModel = StoreShellViewModel(
      StoreShellViewModelArgs(api: api, countries: countries),
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('loads public footer taxonomy in source order', () async {
    final states = <StoreShellStatus>[];
    viewModel.addListener(() => states.add(viewModel.state.status));

    await viewModel.load();

    expect(states, [StoreShellStatus.loading, StoreShellStatus.ready]);
    expect(viewModel.state.collections.single.handle, 'featured');
    expect(
      viewModel.state.categories
          .where((category) => category.parentId == null)
          .map((category) => category.name),
      ['Shirts', 'Sweatshirts', 'Pants', 'Merch'],
    );
    expect(viewModel.state.regions, hasLength(2));
    expect(viewModel.state.selectedCountryCode, const Some('dk'));
    expect(viewModel.state.currencyCode, 'eur');
  });

  test('restores and persists a valid country choice', () async {
    countries.value = const Some('us');

    await viewModel.load();
    expect(viewModel.state.selectedCountryCode, const Some('us'));
    expect(viewModel.state.currencyCode, 'usd');

    await viewModel.selectCountry('dk');
    expect(viewModel.state.selectedCountryCode, const Some('dk'));
    expect(countries.value, const Some('dk'));
  });

  test('one unavailable footer column does not hide the other', () async {
    final resilient = StoreShellViewModel(
      StoreShellViewModelArgs(
        api: _CollectionFailureApi(api),
        countries: countries,
      ),
    );
    addTearDown(resilient.dispose);

    await resilient.load();

    expect(resilient.state.status, StoreShellStatus.ready);
    expect(resilient.state.collections, isEmpty);
    expect(resilient.state.categories, isNotEmpty);
  });
}

final class _MemoryCountryPreferenceStore implements CountryPreferenceStore {
  Option<String> value = const None();

  @override
  Future<Option<String>> read() async => value;

  @override
  Future<void> write(String countryCode) async {
    value = Some(countryCode);
  }
}

final class _CollectionFailureApi implements CommerceApi {
  const _CollectionFailureApi(this.delegate);

  final CommerceApi delegate;

  @override
  Future<ProductCategoryListView> categories({
    String? handle,
    int? limit,
    int? offset,
  }) =>
      delegate.categories(handle: handle, limit: limit, offset: offset);

  @override
  Future<ProductCollectionListView> collections({
    String? handle,
    int? limit,
    int? offset,
  }) =>
      Future.error(Exception('collections unavailable'));

  @override
  Future<SellingRegionListView> regions() => delegate.regions();

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('unused API method');
}
