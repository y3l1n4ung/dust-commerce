import 'package:dust_flutter/route.dart';
import 'package:flutter/widgets.dart';

import 'src/features/account/view_model/account_view_model.dart';
import 'route/routes.g.dart';

export 'package:dust_flutter/route.dart';
export 'route/routes.g.dart';

/// The storefront's router.
///
/// One entrypoint, as Dust requires. Screens declare their own paths with
/// `@AppRoute`; this file only says where the app starts.
@AppRouter(initial: '/', notFound: '/404')
final class CommerceRouter extends $CommerceRouter {
  /// Creates a [CommerceRouter].
  CommerceRouter(
      {required Uri initialLocation, required AccountViewModel account})
      : customerSession = CustomerSessionRouterRefresh(account),
        _initialLocation = Uri(
          path: initialLocation.path,
          query: initialLocation.hasQuery ? initialLocation.query : null,
          fragment:
              initialLocation.hasFragment ? initialLocation.fragment : null,
        );

  /// Customer-session access and router refresh boundary.
  final CustomerSessionRouterRefresh customerSession;
  final Uri _initialLocation;
  bool _initialLocationRead = false;

  @override
  Listenable get refreshListenable => customerSession;

  @override
  RouteInformation parseRouteInformation(RouteInformation information) {
    if (_initialLocationRead) return information;
    _initialLocationRead = true;
    return RouteInformation(uri: _initialLocation);
  }
}

/// Verifies a customer session before activating account-only routes.
final class CustomerGuard implements AsyncRouteGuard<CommerceRoute> {
  /// Creates the route-level customer guard.
  const CustomerGuard(this.customerSession);

  /// Customer-session boundary injected from [CommerceRouter].
  final CustomerSessionRouterRefresh customerSession;

  @override
  Future<CommerceRoute?> canActivate(CommerceRoute route) async {
    final account = customerSession.account;
    await account.restore(force: true);
    return account.state.isAuthenticated ? null : const AccountRoute();
  }
}

/// Notifies the router only when access to customer routes actually changes.
final class CustomerSessionRouterRefresh implements Listenable {
  /// Creates a filtered customer-session router refresh source.
  CustomerSessionRouterRefresh(this.account);

  /// Customer session owner used by generated route guards.
  final AccountViewModel account;
  final Map<VoidCallback, VoidCallback> _relays = {};

  @override
  void addListener(VoidCallback listener) {
    var wasAuthenticated = account.state.isAuthenticated;
    void relay() {
      final isAuthenticated = account.state.isAuthenticated;
      if (isAuthenticated == wasAuthenticated) return;
      wasAuthenticated = isAuthenticated;
      if (!account.isRestoring) listener();
    }

    _relays[listener] = relay;
    account.addListener(relay);
  }

  @override
  void removeListener(VoidCallback listener) {
    final relay = _relays.remove(listener);
    if (relay != null) account.removeListener(relay);
  }
}

/// Medusa-compatible product variant URL behavior.
extension CommerceProductRouteContext on BuildContext {
  /// Selected `v_id` preserved on the active product route, if any.
  String? get productVariantId {
    final route = RouterController.of<CommerceRoute>(this).currentRoute;
    if (route is! ProductRoute) return null;
    final values = generatedRouteUriExtrasOf(route)?.queryParameters['v_id'];
    return values == null || values.isEmpty ? null : values.first;
  }

  /// Replaces the product URL with the selected Medusa `v_id`.
  void replaceProductVariant(String handle, String? variantId) {
    final uri = Uri(
      pathSegments: ['products', handle],
      queryParameters: variantId == null ? null : {'v_id': variantId},
    );
    RouterController.of<CommerceRoute>(this).replace(parseCommerceRoute(uri));
  }
}
