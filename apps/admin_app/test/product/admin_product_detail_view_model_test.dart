import 'dart:io';

import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:dio/dio.dart';
import 'package:dust_server/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient server;
  late AdminProductDetailViewModel detail;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('admin_product_detail');
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
    detail = AdminProductDetailViewModel(
      AdminProductDetailViewModelArgs(
        api: AdminApi(dio, baseUrl: server.origin),
      ),
    );
  });

  tearDown(() async {
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('loads the complete allowlisted merchant product', () async {
    await detail.load('prod_sweatpants');

    expect(detail.state.status, AdminProductDetailStatus.ready);
    final product = (detail.state.product as Some<AdminProductDetail>).value;
    expect(product.title, 'Relaxed Sweatpants');
    expect(product.images, hasLength(2));
    expect(product.options.single.values, ['S', 'M']);
    expect(product.variants, hasLength(2));
    expect(product.categories, ['Pants']);
  });

  test('uses an Option failure for an unknown product', () async {
    await detail.load('prod_missing');

    expect(detail.state.status, AdminProductDetailStatus.failed);
    expect(detail.state.product, const None<AdminProductDetail>());
    expect(
      detail.state.failure,
      const Some('This product no longer exists.'),
    );
  });
}
