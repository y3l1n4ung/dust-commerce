import 'package:dust_flutter/i18n.dart';
import 'package:dust_flutter/route.dart';
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
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: TranslatedText(
          'shop_not_found',
          defaultText: 'That page does not exist',
        ),
      ),
    );
  }
}
