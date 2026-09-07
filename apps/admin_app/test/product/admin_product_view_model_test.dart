import 'dart:io';

import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/product/admin_product_state.dart';
import 'package:admin_app/src/product/admin_product_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:dio/dio.dart';
import 'package:dust_server/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient server;
  late AdminProductViewModel products;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('admin_products');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await seedDevelopmentStore(database);
    await bootstrapAdmin(
      database,
      const AdminCredentials(
        email: 'owner@example.com',
        password: 'correct horse battery staple',
      ),
      nextId: () => 'admin_owner',
      passwordWork: PasswordWorkLimiter(),
    );
    server = await TestClient.serve(buildApp(database));
    final token = await AdminApi(Dio(), baseUrl: server.origin).signIn(
      const AdminCredentials(
        email: 'owner@example.com',
        password: 'correct horse battery staple',
      ),
    );
    final dio = Dio()
      ..options.headers['authorization'] = 'Bearer ${token.token}';
    products = AdminProductViewModel(
      AdminProductViewModelArgs(api: AdminApi(dio, baseUrl: server.origin)),
    );
  });

  tearDown(() async {
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('loads allowlisted products and page metadata', () async {
    await products.load();

    expect(products.state.status, AdminProductStatus.ready);
    expect(products.state.count, 4);
    expect(products.state.products, hasLength(4));
    expect(products.state.products.first.variantCount, greaterThan(0));
  });

  test('search replaces the first page with matching products', () async {
    await products.search(' SWEAT ');

    expect(products.state.status, AdminProductStatus.ready);
    expect(products.state.query, 'SWEAT');
    expect(products.state.count, 2);
    expect(
      products.state.products.map((product) => product.title),
      containsAll(['Vintage Sweatshirt', 'Relaxed Sweatpants']),
    );
  });

  test('removes a deleted product from the current page', () async {
    await products.load();

    final deleted = await products.delete('prod_sweatpants');

    expect(deleted, isTrue);
    expect(products.state.status, AdminProductStatus.ready);
    expect(products.state.count, 3);
    expect(
      products.state.products.map((product) => product.id),
      isNot(contains('prod_sweatpants')),
    );
    expect(products.state.failure, const None<String>());
  });

  test('keeps the current page when a product is already gone', () async {
    await products.load();

    final deleted = await products.delete('prod_missing');

    expect(deleted, isFalse);
    expect(products.state.products, hasLength(4));
    expect(
      products.state.failure,
      const Some('This product no longer exists.'),
    );
  });
}
