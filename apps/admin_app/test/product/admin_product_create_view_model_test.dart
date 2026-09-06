import 'dart:io';

import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/product/admin_product_create_state.dart';
import 'package:admin_app/src/product/admin_product_create_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:dio/dio.dart';
import 'package:dust_server/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient server;
  late AdminProductCreateViewModel create;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('admin_product_create');
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
    final authApi = AdminApi(Dio(), baseUrl: server.origin);
    final token = await authApi.signIn(const AdminCredentials(
      email: 'owner@example.com',
      password: 'correct horse battery staple',
    ));
    final dio = Dio()
      ..options.headers['authorization'] = 'Bearer ${token.token}';
    create = AdminProductCreateViewModel(
      AdminProductCreateViewModelArgs(
        api: AdminApi(dio, baseUrl: server.origin),
      ),
    );
  });

  tearDown(() async {
    await server.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('loads regional currencies and retains the created product', () async {
    await create.load();

    expect(create.state.status, AdminProductCreateStatus.ready);
    expect(create.state.currencyCodes, ['eur', 'usd']);

    final created = await create.create(_product());

    expect(created, isA<Some<AdminProductDetail>>());
    expect(create.state.status, AdminProductCreateStatus.ready);
    expect(create.state.failure, const None<String>());
    expect(
      (create.state.created as Some<AdminProductDetail>).value.handle,
      'desk-lamp',
    );
  });

  test('maps a server conflict without replacing typed state', () async {
    await create.load();
    await create.create(_product());

    final duplicate = await create.create(_product());

    expect(duplicate, const None<AdminProductDetail>());
    expect(create.state.status, AdminProductCreateStatus.ready);
    expect(create.state.created, const None<AdminProductDetail>());
    expect(create.state.failure,
        const Some('That handle or SKU is already in use.'));
  });
}

AdminCreateProduct _product() => const AdminCreateProduct(
      status: AdminProductLifecycle.published,
      title: 'Desk Lamp',
      handle: 'desk-lamp',
      discountable: true,
      options: [
        AdminCreateProductOption(title: 'Finish', values: ['Black']),
      ],
      variants: [
        AdminCreateProductVariant(
          title: 'Black',
          sku: 'LAMP-BLACK',
          inventoryQuantity: 5,
          manageInventory: true,
          allowBackorder: false,
          optionValues: {'Finish': 'Black'},
          prices: [
            AdminCreateProductPrice(currencyCode: 'eur', amount: 4500),
            AdminCreateProductPrice(currencyCode: 'usd', amount: 4900),
          ],
        ),
      ],
    );
