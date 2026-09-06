import 'package:admin_app/src/admin_app.dart';
import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/core/admin_authorization_interceptor.dart';
import 'package:admin_app/src/core/admin_session_store.dart';
import 'package:admin_app/src/product/admin_product_view_model.dart';
import 'package:admin_app/src/product/admin_product_create_view_model.dart';
import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:admin_app/src/session/admin_session_view_model.dart';
import 'package:admin_app/src/theme/admin_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

/// Starts merchant admin on its isolated API and session boundary.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3878',
  );
  final sessions = SecureAdminSessionStore();
  final dio = Dio()
    ..interceptors.add(AdminAuthorizationInterceptor(sessions: sessions));
  final api = AdminApi(dio, baseUrl: baseUrl);
  final session = AdminSessionViewModel(
    AdminSessionViewModelArgs(
      api: api,
      sessions: sessions,
    ),
  );
  final products = AdminProductViewModel(AdminProductViewModelArgs(api: api));
  final productDetail = AdminProductDetailViewModel(
    AdminProductDetailViewModelArgs(api: api),
  );
  final productCreate = AdminProductCreateViewModel(
    AdminProductCreateViewModelArgs(api: api),
  );

  runApp(
    AdminSessionViewModelScope.value(
      value: session,
      child: AdminProductViewModelScope.value(
        value: products,
        child: AdminProductDetailViewModelScope.value(
          value: productDetail,
          child: AdminProductCreateViewModelScope.value(
            value: productCreate,
            child: MorrowAdminApp(themes: AdminThemeController()),
          ),
        ),
      ),
    ),
  );
}
