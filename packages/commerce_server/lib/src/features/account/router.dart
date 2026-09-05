import 'package:commerce_server/src/features/account/handler/handler.dart';
import 'package:dust_server/server.dart';

/// Medusa-shaped authentication routes.
Router accountAuthRoutes() => Router()
  ..route('/customer/emailpass', post(signInHandler))
  ..route('/session', delete(signOutHandler));

/// Customer-account routes.
Router accountStoreRoutes() => Router()
  ..route('/customers', post(registerAccountHandler, status: 201))
  ..route('/customers/me', get(readCurrentCustomerHandler));
