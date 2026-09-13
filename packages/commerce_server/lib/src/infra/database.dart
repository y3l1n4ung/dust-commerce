import 'package:dust_dart/db.dart';
import 'package:dust_db_sqlite3/dust_db_sqlite3.dart';

part 'database.g.dart';

/// The application's database: opening it, migrating it, closing it.
///
/// Separate from the queries because the two have different owners. This is
/// opened once at startup; a DAO is what a handler is given, and a handler
/// has no business closing a connection. Its generated companion embeds the
/// one-shot manifest used by tests and production-history validation.
@SqlxDatabase(type: SqlxDatabaseType.sqlite, migrations: './migrations')
abstract class CommerceDatabase implements DatabaseClient {
  /// Opens the database at [path], applying any unapplied migrations.
  factory CommerceDatabase.open(String path, {SqliteConnectOptions? options}) =
      _$CommerceDatabase.open;

  /// Opens an already SQLx-migrated database without replaying embedded SQL.
  factory CommerceDatabase.connectSqlx(
    String path, {
    SqliteConnectOptions? options,
  }) {
    final connection = Sqlite3Driver.open(path, options: options);
    return _$CommerceDatabase._(connection);
  }

  /// The open connection.
  @override
  DatabaseConnection get connection;
}

/// SQLx versions embedded in this binary, ordered by migration filename.
List<int> get commerceSqlxMigrationVersions => List.unmodifiable(
      _$commerceDatabaseMigrations.keys
          .where((name) => name.endsWith('.up.sql'))
          .map((name) => int.parse(name.substring(0, name.indexOf('_')))),
    );

/// Rejects databases that were not fully migrated for this server binary.
Future<void> requireCommerceSqlxMigrations(
  CommerceDatabase database,
) async {
  final history = await (database.connection as Executor).raw.fetch(
    'SELECT version, success FROM _sqlx_migrations ORDER BY version',
    const [],
  );
  final rows = switch (history) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError(
        'SQLx migration history is missing or unreadable. '
        'Run `sqlx migrate run` before starting dust-commerce. Cause: $error',
      ),
  };
  if (rows.isEmpty) {
    throw StateError(
      'SQLx migration history is empty. Run `sqlx migrate run` before '
      'starting dust-commerce.',
    );
  }

  final expected = commerceSqlxMigrationVersions.toSet();
  final successful = <int>{};
  final failed = <int>[];
  for (final row in rows) {
    final version = row.read<int>('version');
    if (row.readBool('success')) {
      successful.add(version);
    } else {
      failed.add(version);
    }
  }
  final missing = expected.difference(successful).toList()..sort();
  final unexpected = successful.difference(expected).toList()..sort();
  if (missing.isEmpty && unexpected.isEmpty && failed.isEmpty) return;

  throw StateError(
    'SQLx migration history does not match this server binary. '
    'Missing: ${missing.isEmpty ? 'none' : missing.join(', ')}. '
    'Unexpected: ${unexpected.isEmpty ? 'none' : unexpected.join(', ')}. '
    'Failed: ${failed.isEmpty ? 'none' : failed.join(', ')}.',
  );
}

/// What a file-backed database wants when more than one isolate has it open.
///
/// WAL lets readers run while a writer holds the file, which is the difference
/// between a database that serves requests under load and one that returns
/// `SQLITE_BUSY`. Foreign keys are on because the schema declares them and
/// SQLite ignores them unless asked — a cascade that silently does nothing is
/// worse than no cascade, since the schema claims otherwise.
SqliteConnectOptions get commerceOptions => const SqliteConnectOptions(
      journalMode: SqliteJournalMode.wal,
      busyTimeout: Duration(seconds: 5),
      foreignKeys: true,
    );

/// Production options require SQLx to create the database before startup.
SqliteConnectOptions get commerceSqlxOptions => const SqliteConnectOptions(
      createIfMissing: false,
      journalMode: SqliteJournalMode.wal,
      busyTimeout: Duration(seconds: 5),
      foreignKeys: true,
    );
