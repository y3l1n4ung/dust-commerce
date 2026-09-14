import 'package:commerce_server/src/features/admin_customer_group/handler/create.dart';
import 'package:commerce_server/src/features/admin_customer_group/handler/read.dart';
import 'package:commerce_server/src/features/admin_customer_group/list_handler.dart';
import 'package:dust_server/server.dart';

/// Customer-group routes merged beneath the parent Admin authentication layer.
Router adminCustomerGroupRoutes() => Router()
  ..route(
    '/customer-groups',
    get(listAdminCustomerGroupsHandler).post(
      createAdminCustomerGroupHandler,
    ),
  )
  ..route(
    '/customer-groups/{id}',
    get(readAdminCustomerGroupHandler),
  );
