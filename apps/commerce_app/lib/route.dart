import 'package:dust_flutter/route.dart';

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
  CommerceRouter();
}
