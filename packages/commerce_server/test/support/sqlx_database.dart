import 'package:commerce_server/commerce_server.dart';

/// Records production-shaped SQLx history around a schema prepared for tests.
Future<void> recordSqlxHistoryForTest(
  CommerceDatabase database,
  Iterable<int> versions,
) async {
  await queryExecute(r'''
CREATE TABLE _sqlx_migrations (
  version BIGINT PRIMARY KEY,
  description TEXT NOT NULL,
  installed_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  success BOOLEAN NOT NULL,
  checksum BLOB NOT NULL,
  execution_time BIGINT NOT NULL
)
''', []).execute(database.connection);
  for (final version in versions) {
    await queryExecute(
      'INSERT INTO _sqlx_migrations '
      '(version, description, success, checksum, execution_time) '
      "VALUES (?, 'test', 1, x'00', 0)",
      [version],
    ).execute(database.connection);
  }
}
