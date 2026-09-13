import 'package:commerce_server/src/features/admin_return/handler.dart';
import 'package:dust_server/server.dart';

/// Return routes merged beneath the parent Admin authentication layer.
Router adminReturnRoutes() =>
    Router()..route('/returns', get(listAdminReturnsHandler));
