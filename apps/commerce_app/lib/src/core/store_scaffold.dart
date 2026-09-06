import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import '../features/shell/view/country_select.dart';

/// The navigation shell translated from Medusa DTC Nav and SideMenu.
class StoreScaffold extends StatelessWidget {
  /// Creates the shared storefront shell.
  const StoreScaffold({required this.body, super.key});

  /// Route content below the fixed-height storefront header.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 88,
        leading: Builder(
          builder: (context) => TextButton(
            onPressed: Scaffold.of(context).openDrawer,
            child: const TranslatedText(
              'shop_menu',
              defaultText: 'Menu',
            ),
          ),
        ),
        title: TextButton(
          onPressed: () => context.navigator.catalog().go(),
          child: const TranslatedText(
            'shop_brand',
            defaultText: 'MORROW',
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 1024)
            TextButton(
              onPressed: () => context.navigator.account().go(),
              child: const TranslatedText(
                'shop_account_title',
                defaultText: 'Account',
              ),
            ),
          if (MediaQuery.sizeOf(context).width >= 1024)
            const SizedBox(width: 12),
          const CartPreview(),
          const SizedBox(width: 12),
        ],
      ),
      drawer: const _StoreMenu(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                const CartMismatchBanner(),
                Expanded(child: body),
              ],
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: FreeShippingPriceNudge(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreMenu extends StatelessWidget {
  const _StoreMenu();

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: StoreColors.inverted.withValues(alpha: 0.96),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: Navigator.of(context).pop,
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Spacer(),
                _MenuLink(
                  label: context.tr('shop_home', defaultText: 'Home'),
                  onPressed: () => _go(
                    context,
                    () => context.navigator.catalog().go(),
                  ),
                ),
                _MenuLink(
                  label: context.tr('shop_title', defaultText: 'Store'),
                  onPressed: () => _go(
                    context,
                    () => context.navigator.store().go(),
                  ),
                ),
                _MenuLink(
                  label: context.tr(
                    'shop_account_title',
                    defaultText: 'Account',
                  ),
                  onPressed: () => _go(
                    context,
                    () => context.navigator.account().go(),
                  ),
                ),
                _MenuLink(
                  label: context.tr('shop_cart_title', defaultText: 'Cart'),
                  onPressed: () => _go(
                    context,
                    () => context.navigator.cart().go(),
                  ),
                ),
                const Spacer(),
                const StoreLanguageSelect(),
                const SizedBox(height: 24),
                const StoreCountrySelect(),
                const SizedBox(height: 24),
                Text(
                  '© ${DateTime.now().year} Morrow',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );

  void _go(BuildContext context, VoidCallback navigate) {
    Navigator.of(context).pop();
    navigate();
  }
}

class _MenuLink extends StatelessWidget {
  const _MenuLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w400,
          ),
        ),
        child: Text(label),
      );
}
