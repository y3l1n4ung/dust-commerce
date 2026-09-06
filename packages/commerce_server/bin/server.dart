import 'dart:async';
import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:dust_server/server.dart';

Future<void> main() async {
  final config = _ServerConfig.fromEnvironment(Platform.environment);
  final transferMail = OrderTransferMailConfig.optionFromEnvironment(
    Platform.environment,
  );
  final transferMailer = transferMail.match<OrderTransferMailer>(
    some: (value) => value.build(),
    none: UnavailableOrderTransferMailer.new,
  );
  await File(config.databasePath).parent.create(recursive: true);
  final database = CommerceDatabase.open(
    config.databasePath,
    options: commerceOptions,
  );

  try {
    if (config.seed) await seedDevelopmentStore(database);
    final app = buildApp(database, orderTransferMailer: transferMailer)
      ..layer(const SecurityHeaders())
      ..layer(const RequestId());
    if (config.allowedOrigins.isNotEmpty) {
      app.layer(storefrontCors(config.allowedOrigins));
    }

    final server = await serve(app, config.address, config.port);
    stdout.writeln('dust-commerce listening on http://'
        '${server.address.host}:${server.port}');

    await _waitForShutdownSignal();
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

Future<void> _waitForShutdownSignal() async {
  final signal = Completer<void>();
  final subscriptions = <StreamSubscription<ProcessSignal>>[];

  void stop(ProcessSignal _) {
    if (!signal.isCompleted) signal.complete();
  }

  subscriptions
    ..add(ProcessSignal.sigterm.watch().listen(stop))
    ..add(ProcessSignal.sigint.watch().listen(stop));
  await signal.future;
  await Future.wait(subscriptions.map((subscription) => subscription.cancel()));
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
    final portText = environment['COMMERCE_PORT'] ?? '3878';
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
