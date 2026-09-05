import 'package:dust_flutter/route.dart';
import 'package:flutter/widgets.dart';

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
  CommerceRouter({required Uri initialLocation})
      : _initialLocation = Uri(
          path: initialLocation.path,
          query: initialLocation.hasQuery ? initialLocation.query : null,
          fragment:
              initialLocation.hasFragment ? initialLocation.fragment : null,
        );

  final Uri _initialLocation;
  bool _initialLocationRead = false;

  @override
  RouteInformation parseRouteInformation(RouteInformation information) {
    if (_initialLocationRead) return information;
    _initialLocationRead = true;
    return RouteInformation(uri: _initialLocation);
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
