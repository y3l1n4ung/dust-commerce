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
    directory = await Directory.systemTemp.createTemp('admin_product_option');
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
    final mediaStorage = LocalAdminMediaStorage(
      root: Directory('${directory.path}/media'),
      publicBaseUrl: Uri.parse('http://media.test'),
      nextKey: () => 'option_media_key',
    );
    await mediaStorage.prepare();
    server = await TestClient.serve(buildApp(
      database,
      mediaStorage: mediaStorage,
    ));
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

  test('publishes refreshed detail after an option update', () async {
    await detail.load('prod_sweatpants');

    final saved = await detail.updateOption(
      'prod_sweatpants',
      'opt_sweatpants_size',
      const AdminUpdateProductOption(
        title: 'Waist size',
        values: ['M', 'S', 'XL'],
      ),
    );

    expect(saved, isTrue);
    expect(detail.state.status, AdminProductDetailStatus.ready);
    final product = (detail.state.product as Some<AdminProductDetail>).value;
    expect(product.options.single.title, 'Waist size');
    expect(product.options.single.values, ['M', 'S', 'XL']);
    expect(detail.state.failure, const None<String>());
  });

  test('keeps detail and explains a selected-value conflict', () async {
    await detail.load('prod_sweatpants');

    final saved = await detail.updateOption(
      'prod_sweatpants',
      'opt_sweatpants_size',
      const AdminUpdateProductOption(title: 'Size', values: ['S']),
    );

    expect(saved, isFalse);
    expect(detail.state.status, AdminProductDetailStatus.ready);
    expect(detail.state.product, isA<Some<AdminProductDetail>>());
    expect(
      detail.state.failure,
      const Some('A product variant still uses one of these values.'),
    );
  });

  test('distinguishes an option-title conflict', () async {
    await detail.load('prod_tshirt');

    final saved = await detail.updateOption(
      'prod_tshirt',
      'opt_tshirt_size',
      const AdminUpdateProductOption(
        title: 'Color',
        values: ['S', 'M', 'L', 'XL'],
      ),
    );

    expect(saved, isFalse);
    expect(
      detail.state.failure,
      const Some('Another option already uses this title.'),
    );
  });
}
