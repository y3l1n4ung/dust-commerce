import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/i18n/app_i18n.g.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

/// Runs the storefront.
///
/// The API base URL is compile-time configurable so the same build can point
/// at a local server or a deployed one without a code change:
/// `flutter run --dart-define=API_BASE_URL=https://…`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final sessions = SecureAuthSessionStore();
  final dio = Dio()
    ..interceptors.add(AuthorizationInterceptor(sessions: sessions));

  runApp(
    AppI18n(
      child: CommerceApp(
        api: CommerceApi(dio, baseUrl: baseUrl),
        sessions: sessions,
        initialLocation: kIsWeb
            ? Uri.base
            : Uri.parse(
                WidgetsBinding.instance.platformDispatcher.defaultRouteName,
              ),
      ),
    ),
  );
}

/// The storefront.
class CommerceApp extends StatefulWidget {
  /// Creates a [CommerceApp].
  const CommerceApp({
    required this.api,
    required this.sessions,
    required this.initialLocation,
    super.key,
  });

  /// The storefront API every view model is given.
  final CommerceApi api;

  /// Secure customer-session persistence shared with Dio authorization.
  final AuthSessionStore sessions;

  /// Browser or platform location captured before the router can normalize it.
  final Uri initialLocation;

  @override
  State<CommerceApp> createState() => _CommerceAppState();
}

class _CommerceAppState extends State<CommerceApp> {
  late final AccountViewModel _account;
  late final CommerceRouter _router;
  late final RouterConfig<CommerceRoute> _routerConfig;
  bool _routerReady = false;

  @override
  void initState() {
    super.initState();
    _account = AccountViewModel(
      AccountViewModelArgs(api: widget.api, sessions: widget.sessions),
    );
    _router = CommerceRouter(
      initialLocation: widget.initialLocation,
      account: _account,
    );
    // Let Dust's initial refresh settle before an async deep-link guard runs.
    _routerConfig = _router.config;
    Future<void>.microtask(() {
      if (mounted) setState(() => _routerReady = true);
    });
  }

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_routerReady) return const SizedBox.shrink();
    final i18n = I18nScope.of(context);
    final app = MaterialApp.router(
      onGenerateTitle: (context) => context.tr(
        'shop_brand',
        defaultText: 'Morrow',
      ),
      debugShowCheckedModeBanner: false,
      locale: appI18nLocaleOf(i18n.locale),
      supportedLocales: appI18nSupportedLocales,
      localizationsDelegates: appI18nLocalizationsDelegates,
      theme: StoreTheme.light,
      routerConfig: _routerConfig,
    );

    return AccountViewModelScope.value(
      value: _account,
      child: AccountOrdersViewModelScope(
        args: (_) => AccountOrdersViewModelArgs(api: widget.api),
        create: (_, args) => AccountOrdersViewModel(args),
        child: CartViewModelScope(
          args: (_) => CartViewModelArgs(
            api: widget.api,
            cartIds: SecureCartIdStore(),
          ),
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
        ),
      ),
    );
  }
}
