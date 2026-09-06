import 'dart:async';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/i18n/app_i18n.g.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_dart/http.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

part 'src/app/view_model_scopes.dart';

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
        countries: SecureCountryPreferenceStore(),
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
    required this.countries,
    required this.initialLocation,
    super.key,
  });

  /// The storefront API every view model is given.
  final CommerceApi api;

  /// Secure customer-session persistence shared with Dio authorization.
  final AuthSessionStore sessions;

  /// Persisted country selection shared by storefront routes.
  final CountryPreferenceStore countries;

  /// Browser or platform location captured before the router can normalize it.
  final Uri initialLocation;

  @override
  State<CommerceApp> createState() => _CommerceAppState();
}

class _CommerceAppState extends State<CommerceApp> {
  late final AccountViewModel _account;
  late final AddressBookViewModel _addresses;
  late final AccountOrderDetailViewModel _orderDetail;
  late final AccountOrdersViewModel _orders;
  late final CartViewModel _cart;
  late final CheckoutViewModel _checkout;
  late final StoreShellViewModel _shell;
  late final CommerceRouter _router;
  late final RouterConfig<CommerceRoute> _routerConfig;
  bool _routerReady = false;
  String? _accountOwnerId;

  @override
  void initState() {
    super.initState();
    _account = AccountViewModel(
      AccountViewModelArgs(api: widget.api, sessions: widget.sessions),
    );
    _addresses = AddressBookViewModel(
      AddressBookViewModelArgs(api: widget.api),
    );
    _orders = AccountOrdersViewModel(
      AccountOrdersViewModelArgs(api: widget.api),
    );
    _orderDetail = AccountOrderDetailViewModel(
      AccountOrderDetailViewModelArgs(api: widget.api),
    );
    _shell = StoreShellViewModel(
      StoreShellViewModelArgs(
        api: widget.api,
        countries: widget.countries,
      ),
    );
    _cart = CartViewModel(
      CartViewModelArgs(
        api: widget.api,
        cartIds: SecureCartIdStore(),
        selectedRegion: () => _shell.state.selectedRegion,
      ),
    );
    _checkout = CheckoutViewModel(
      CheckoutViewModelArgs(
        api: widget.api,
        cart: _cart,
        receipts: SecureOrderReceiptStore(),
        currentCustomer: () => _account.state.customer,
      ),
    );
    _account.addListener(_onAccountIdentityChanged);
    _router = CommerceRouter(
      initialLocation: widget.initialLocation,
      account: _account,
      cart: _cart,
    );
    _routerConfig = _router.config;
    unawaited(_prepareStorefront());
  }

  Future<void> _prepareStorefront() async {
    await _shell.load();
    if (mounted) setState(() => _routerReady = true);
  }

  @override
  void dispose() {
    _account.removeListener(_onAccountIdentityChanged);
    _checkout.dispose();
    _shell.dispose();
    _cart.dispose();
    _addresses.dispose();
    _orderDetail.dispose();
    _orders.dispose();
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

    return _storefrontScopes(
      api: widget.api,
      account: _account,
      addresses: _addresses,
      orderDetail: _orderDetail,
      orders: _orders,
      cart: _cart,
      checkout: _checkout,
      shell: _shell,
      child: app,
    );
  }

  void _onAccountIdentityChanged() {
    final ownerId = _account.state.customer?.id;
    if (ownerId == _accountOwnerId) return;
    _accountOwnerId = ownerId;
    _addresses.reset();
    _orderDetail.reset();
    _orders.reset();
    _checkout.reset();
    if (ownerId == null) {
      unawaited(_cart.clearForSignOut());
    } else {
      unawaited(_cart.transferToCustomer());
    }
  }
}
