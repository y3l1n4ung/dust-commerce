import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:test/test.dart';

void main() {
  test('development seed is complete and idempotent', () async {
    final directory = await Directory.systemTemp.createTemp('commerce_seed');
    final database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    await seedDevelopmentStore(database);
    await seedDevelopmentStore(database);

    expect(await _count(database, 'products'), 4);
    expect(await _count(database, 'product_variants'), 14);
    expect(await _count(database, 'product_option_values'), 12);
    expect(await _count(database, 'variant_option_values'), 22);
    expect(await _count(database, 'product_images'), 10);
    expect(await _count(database, 'shipping_options'), 3);
    expect(await _count(database, 'shipping_option_price_rules'), 1);
    expect(await _count(database, 'promotions'), 1);

    final thumbnails = await queryScalar<int>(
      'SELECT COUNT(*) FROM products WHERE thumbnail LIKE ?',
      ['https://%'],
    ).fetchOne(database.executor);
    expect(thumbnails, 4);

    final images = await queryScalar<int>(
      "SELECT COUNT(*) FROM product_images WHERE product_id = 'prod_tshirt'",
      const [],
    ).fetchOne(database.executor);
    expect(images, 4);
  });
}

Future<int> _count(CommerceDatabase database, String table) async {
  final rows = await queryRaw('SELECT COUNT(*) FROM $table', const [])
      .fetch(database.connection as Executor);
  return rows.single.readIndex<int>(0);
}
