import 'package:commerce_server/src/features/admin_order/handler.dart';
import 'package:commerce_server/src/features/admin_order/detail_handler.dart';
import 'package:dust_server/server.dart';

/// Order routes merged beneath the parent Admin authentication layer.
Router adminOrderRoutes() => Router()
  ..route('/orders', get(listAdminOrdersHandler))
  ..route('/orders/{id}', get(readAdminOrderHandler));
