import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/i18n/app_i18n.g.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_dart/http.dart';
import 'package:flutter/material.dart';

/// Runs the storefront.
///
/// The API base URL is compile-time configurable so the same build can point
/// at a local server or a deployed one without a code change:
/// `flutter run --dart-define=API_BASE_URL=https://…`.
void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  runApp(
    AppI18n(
      child: CommerceApp(api: CommerceApi(Dio(), baseUrl: baseUrl)),
    ),
  );
}

/// The storefront.
class CommerceApp extends StatelessWidget {
  /// Creates a [CommerceApp].
  const CommerceApp({required this.api, super.key});

  /// The storefront API every view model is given.
  final CommerceApi api;

  @override
  Widget build(BuildContext context) {
    return CatalogViewModelScope(
      args: (_) => CatalogViewModelArgs(api: api),
      create: (_, args) => CatalogViewModel(args),
      child: MaterialApp.router(
        title: 'Commerce',
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        routerConfig: CommerceRouter().config,
      ),
    );
  }
}
