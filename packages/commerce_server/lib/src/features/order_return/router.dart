import 'package:commerce_server/src/features/account/extractor.dart';
import 'package:commerce_server/src/features/order_return/handler/handler.dart';
import 'package:dust_server/server.dart';

/// Authenticated Store return routes.
Router orderReturnRoutes() => Router()
  ..routeLayer(fromExtractor(const CustomerAuth()))
  ..route('/returns', post(createOrderReturnHandler, status: 201));
