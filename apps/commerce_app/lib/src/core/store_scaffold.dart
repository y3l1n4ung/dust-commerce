import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'store_menu.dart';

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
      drawerScrimColor: Colors.transparent,
      drawer: const StoreMenu(),
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
