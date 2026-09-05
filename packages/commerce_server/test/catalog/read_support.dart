import 'package:commerce_server/commerce_server.dart';

/// Seeds the catalogue states exercised by the storefront read tests.
Future<void> seedCatalogRead(CommerceDatabase database) async {
  Future<void> run(String sql) =>
      queryExecute(sql, []).execute(database.executor);

  await run(
    r"INSERT INTO products (id, title, handle, weight, status) VALUES "
    r"('prod_shirt', 'T-Shirt', 't-shirt', 400, 'published'), "
    r"('prod_mug', 'Mug', 'mug', NULL, 'published'), "
    r"('prod_secret', 'Hoodie', 'secret-hoodie', NULL, 'draft')",
  );
  await run(
    r"INSERT INTO product_images (id, product_id, url, rank) VALUES "
    r"('img_shirt', 'prod_shirt', 'https://example.test/shirt-front.png', 0)",
  );
  await run(
    r"INSERT INTO product_variants "
    r"(id, product_id, title, inventory_quantity) VALUES "
    r"('var_small', 'prod_shirt', 'Small', 5), "
    r"('var_large', 'prod_shirt', 'Large', 2)",
  );
  await run(
    r"INSERT INTO product_options (id, product_id, title, values_csv) VALUES "
    r"('opt_size', 'prod_shirt', 'Size', 'Small,Large')",
  );
  await run(
    r"INSERT INTO variant_option_values (variant_id, option_id, value) VALUES "
    r"('var_small', 'opt_size', 'Small'), "
    r"('var_large', 'opt_size', 'Large')",
  );
  await run(
    r"INSERT INTO variant_prices (variant_id, currency_code, amount) VALUES "
    r"('var_small', 'usd', 1999), "
    r"('var_large', 'usd', 2199), "
    r"('var_small', 'eur', 1799)",
  );
}
