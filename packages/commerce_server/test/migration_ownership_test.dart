import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:test/test.dart';

import 'support/sqlx_database.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('commerce_sqlx_owner');
  });

  tearDown(() => directory.delete(recursive: true));

  test('connects without replaying migrations after SQLx owns history',
      () async {
    final path = '${directory.path}/commerce.db';
    final setup = CommerceDatabase.open(path, options: commerceOptions);
    await recordSqlxHistoryForTest(
      setup,
      commerceSqlxMigrationVersions,
    );
    await setup.close();

    final database = CommerceDatabase.connectSqlx(
      path,
      options: commerceOptions,
    );
    addTearDown(database.close);

    await requireCommerceSqlxMigrations(database);
    final products = await queryScalar<int>('SELECT COUNT(*) FROM products', [])
        .fetchOne(database.connection as Executor);
    expect(products, 0);
  });

  test('rejects a database without SQLx migration history', () async {
    final database = CommerceDatabase.connectSqlx(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    addTearDown(database.close);

    await expectLater(
      requireCommerceSqlxMigrations(database),
      throwsA(isA<StateError>()),
    );
  });

  test('production options do not create a missing database', () {
    final path = '${directory.path}/missing.db';

    expect(
      () => CommerceDatabase.connectSqlx(
        path,
        options: commerceSqlxOptions,
      ),
      throwsA(isA<SqlxError>()),
    );
    expect(File(path).existsSync(), isFalse);
  });

  test('rejects incomplete SQLx migration history', () async {
    final path = '${directory.path}/commerce.db';
    final setup = CommerceDatabase.open(path, options: commerceOptions);
    await recordSqlxHistoryForTest(
      setup,
      commerceSqlxMigrationVersions.take(
        commerceSqlxMigrationVersions.length - 1,
      ),
    );
    await setup.close();
    final database = CommerceDatabase.connectSqlx(
      path,
      options: commerceOptions,
    );
    addTearDown(database.close);

    await expectLater(
      requireCommerceSqlxMigrations(database),
      throwsA(isA<StateError>()),
    );
  });
}
