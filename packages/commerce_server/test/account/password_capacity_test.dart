import 'dart:async';
import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:dust_server/testing.dart';
import 'package:test/test.dart';

void main() {
  test('password work rejects excess concurrent requests', () async {
    final limiter = PasswordWorkLimiter(maxConcurrent: 1);
    final release = Completer<void>();
    final occupied = limiter.run(() => release.future);

    await expectLater(
      limiter.run(() async {}),
      throwsA(isA<PasswordCapacityException>()),
    );

    release.complete();
    await occupied;
  });

  test('registration answers 429 when Argon2 capacity is occupied', () async {
    final directory = await Directory.systemTemp.createTemp('commerce_limit');
    final database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    final limiter = PasswordWorkLimiter(maxConcurrent: 1);
    final client = TestClient(buildApp(database, passwordWork: limiter));
    while (!limiter.isIdle) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    final release = Completer<void>();
    final occupied = limiter.run(() => release.future);
    addTearDown(() async {
      release.complete();
      await occupied;
      await client.close();
      await database.close();
      await directory.delete(recursive: true);
    });

    final response = await (client.post('/store/customers')
          ..json({
            'email': 'ada@example.com',
            'password': 'correct horse battery staple',
          }))
        .send();

    expect(response.statusCode, 429);
  });
}
