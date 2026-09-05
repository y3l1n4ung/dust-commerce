import 'dart:async';
import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:dust_server/server.dart';

Future<void> main() async {
  final config = _ServerConfig.fromEnvironment(Platform.environment);
  await File(config.databasePath).parent.create(recursive: true);
  final database = CommerceDatabase.open(
    config.databasePath,
    options: commerceOptions,
  );

  try {
    if (config.seed) await seedDevelopmentStore(database);
    final app = buildApp(database)
      ..layer(const SecurityHeaders())
      ..layer(const RequestId());
    if (config.allowedOrigins.isNotEmpty) {
      app.layer(
        Cors(
          origins: AllowedOrigins.only(config.allowedOrigins),
          methods: const {'GET', 'POST', 'DELETE', 'OPTIONS'},
          headers: const {'accept', 'authorization', 'content-type'},
          maxAge: const Duration(minutes: 10),
        ),
      );
    }

    final server = await serve(app, config.address, config.port);
    stdout.writeln('dust-commerce listening on http://'
        '${server.address.host}:${server.port}');

    await Future.any([
      ProcessSignal.sigterm.watch().first,
      ProcessSignal.sigint.watch().first,
    ]);
    final drained = await server.close(drain: const Duration(seconds: 15));
    if (!drained) {
      stderr.writeln(
        'Shutdown deadline passed with ${server.inFlight} request(s) active.',
      );
      exitCode = 1;
    }
  } finally {
    await database.close();
  }
}

final class _ServerConfig {
  const _ServerConfig({
    required this.address,
    required this.port,
    required this.databasePath,
    required this.seed,
    required this.allowedOrigins,
  });

  factory _ServerConfig.fromEnvironment(Map<String, String> environment) {
    final bind = environment['COMMERCE_BIND'] ?? '127.0.0.1';
    final portText = environment['COMMERCE_PORT'] ?? '8080';
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      throw FormatException('COMMERCE_PORT must be between 1 and 65535.');
    }

    return _ServerConfig(
      address: InternetAddress(bind),
      port: port,
      databasePath: environment['COMMERCE_DATABASE_PATH'] ?? 'commerce.db',
      seed: environment['COMMERCE_SEED'] == 'true',
      allowedOrigins: {
        for (final origin
            in (environment['COMMERCE_ALLOWED_ORIGINS'] ?? '').split(','))
          if (origin.trim().isNotEmpty) origin.trim(),
      },
    );
  }

  final InternetAddress address;
  final Set<String> allowedOrigins;
  final String databasePath;
  final int port;
  final bool seed;
}
