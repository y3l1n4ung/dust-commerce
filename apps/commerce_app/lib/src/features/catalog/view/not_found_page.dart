import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Shown when a URL matches no route.
///
/// A storefront on the web takes whatever URL somebody pastes, so this is a
/// screen a real customer reaches, not a developer aid.
@AppRoute('/404', name: 'notFound')
class NotFoundPage extends StatelessWidget {
  /// Creates a [NotFoundPage].
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(bottom: 64),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TranslatedText(
                  'shop_not_found_title',
                  defaultText: 'Page not found',
                  style: TextStyle(
                    fontSize: 30,
                    height: 48 / 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const TranslatedText(
                  'shop_not_found_body',
                  defaultText: 'The page you tried to access does not exist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 20 / 12),
                ),
                const SizedBox(height: 16),
                StoreInteractiveLink(
                  onPressed: () => context.navigator.catalog().go(),
                  child: const TranslatedText(
                    'shop_not_found_frontpage',
                    defaultText: 'Go to frontpage',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
