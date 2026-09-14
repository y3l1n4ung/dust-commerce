import 'package:commerce_server/src/features/admin_customer/create_handler.dart';
import 'package:commerce_server/src/features/admin_customer/detail_handler.dart';
import 'package:commerce_server/src/features/admin_customer/handler.dart';
import 'package:commerce_server/src/features/admin_customer/update_handler.dart';
import 'package:dust_server/server.dart';

/// Customer routes merged beneath the parent Admin authentication layer.
Router adminCustomerRoutes() => Router()
  ..route(
    '/customers',
    get(listAdminCustomersHandler).post(createAdminCustomerHandler),
  )
  ..route(
    '/customers/{id}',
    get(readAdminCustomerHandler).patch(updateAdminCustomerHandler),
  );
