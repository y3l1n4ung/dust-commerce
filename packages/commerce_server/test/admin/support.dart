import 'dart:io';

import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/commerce_server.dart';
import 'package:dust_server/testing.dart';
import 'package:test/test.dart';

/// Real app and temporary database used by admin route tests.
final class AdminHarness {
  AdminHarness._(this.directory, this.database, this.client);

  /// Synthetic password used only inside temporary test databases.
  static const password = 'correct horse battery staple';

  /// Starts a migrated app with one bootstrapped administrator.
  static Future<AdminHarness> start({bool seedStore = false}) async {
    final directory = await Directory.systemTemp.createTemp('commerce_admin');
    final database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    var bootstrapId = 0;
    final created = await bootstrapAdmin(
      database,
      const AdminCredentials(
        email: ' OWNER@EXAMPLE.COM ',
        password: password,
      ),
      nextId: () => 'admin_${++bootstrapId}',
      passwordWork: PasswordWorkLimiter(),
      firstName: 'Store',
      lastName: 'Owner',
    );
    if (created
        case Ok(value: Ok<AdminUserResponse, AdminBootstrapFailure>())) {
      // Start only after the non-public bootstrap succeeds.
    } else {
      fail('Admin bootstrap failed: $created');
    }
    if (seedStore) await seedDevelopmentStore(database);
    var requestId = 100;
    return AdminHarness._(
      directory,
      database,
      TestClient(buildApp(
        database,
        nextId: () => 'id_${++requestId}',
        now: () => DateTime.utc(2026, 9, 6, 12),
      )),
    );
  }

  /// In-memory request client.
  final TestClient client;

  /// Temporary migrated database.
  final CommerceDatabase database;

  /// Temporary directory deleted by [stop].
  final Directory directory;

  /// Sends one admin password exchange.
  Future<TestResponse> signIn({
    String email = 'owner@example.com',
    String password = AdminHarness.password,
  }) =>
      (client.post('/auth/admin/emailpass')
            ..json({'email': email, 'password': password}))
          .send();

  /// Returns one valid raw token for request tests.
  Future<String> adminToken() async {
    final response = await signIn();
    response.assertOk();
    return (response.json! as Map<String, Object?>)['token']! as String;
  }

  /// Executes a read-only assertion query.
  Future<List<Row>> raw(String sql) =>
      queryRaw(sql, []).fetch(database.connection as Executor);

  /// Closes and removes every temporary resource.
  Future<void> stop() async {
    await client.close();
    await database.close();
    await directory.delete(recursive: true);
  }
}
