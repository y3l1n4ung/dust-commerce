import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/i18n/app_i18n.g.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

/// Runs the storefront.
///
/// The API base URL is compile-time configurable so the same build can point
/// at a local server or a deployed one without a code change:
/// `flutter run --dart-define=API_BASE_URL=https://…`.
void main() {
  usePathUrlStrategy();
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
class CommerceApp extends StatefulWidget {
  /// Creates a [CommerceApp].
  const CommerceApp({required this.api, super.key});

  /// The storefront API every view model is given.
  final CommerceApi api;

  @override
  State<CommerceApp> createState() => _CommerceAppState();
}

class _CommerceAppState extends State<CommerceApp> {
  final CommerceRouter _router = CommerceRouter();

  @override
  Widget build(BuildContext context) {
    final i18n = I18nScope.of(context);
    final app = MaterialApp.router(
      onGenerateTitle: (context) => context.tr(
        'shop_brand',
        defaultText: 'Dust Store',
      ),
      debugShowCheckedModeBanner: false,
      locale: appI18nLocaleOf(i18n.locale),
      supportedLocales: appI18nSupportedLocales,
      localizationsDelegates: appI18nLocalizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff111827),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xff52525b),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: Border(
            bottom: BorderSide(color: Color(0xffe5e5e5)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xff52525b)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff18181b),
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
      routerConfig: _router.config,
    );

    return CartViewModelScope(
      args: (_) => CartViewModelArgs(api: widget.api),
      create: (_, args) => CartViewModel(args),
      child: ProductViewModelScope(
        args: (_) => ProductViewModelArgs(api: widget.api),
        create: (_, args) => ProductViewModel(args),
        child: CatalogViewModelScope(
          args: (_) => CatalogViewModelArgs(api: widget.api),
          create: (_, args) => CatalogViewModel(args),
          child: app,
        ),
      ),
    );
  }
}
