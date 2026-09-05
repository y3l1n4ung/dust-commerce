import 'package:dust_dart/db.dart';
import 'package:dust_db_sqlite3/dust_db_sqlite3.dart';

part 'database.g.dart';

/// The application's database: opening it, migrating it, closing it.
///
/// Separate from the queries because the two have different owners. This is
/// opened once at startup; a DAO is what a handler is given, and a handler
/// has no business closing a connection.
@SqlxDatabase(type: SqlxDatabaseType.sqlite, migrations: './migrations')
abstract class CommerceDatabase implements DatabaseClient {
  /// Opens the database at [path], applying any unapplied migrations.
  factory CommerceDatabase.open(String path, {SqliteConnectOptions? options}) =
      _$CommerceDatabase.open;

  /// The open connection.
  @override
  DatabaseConnection get connection;
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
