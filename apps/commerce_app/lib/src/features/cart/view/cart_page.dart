import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// The current server cart.
@AppRoute('/cart', name: 'cart', guards: [])
class CartPage extends StatelessWidget {
  /// Creates the cart page.
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watchCartViewModel().value;
    final cart = state.cart;

    return StoreScaffold(
      body: cart == null || cart.cart.isEmpty
          ? const _EmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
              children: [
                const TranslatedText(
                  'shop_cart_title',
                  defaultText: 'Cart',
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 32),
                for (final item in cart.cart.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title),
                    subtitle: Text(item.variantTitle ?? ''),
                    trailing: Text(
                      '${item.quantity} × ${formatMoney(item.unitPrice)}',
                    ),
                  ),
                const Divider(height: 48),
                _Total(
                  label: const TranslatedText(
                    'shop_subtotal',
                    defaultText: 'Subtotal',
                  ),
                  value: formatMoney(cart.subtotal),
                ),
                _Total(
                  label: const TranslatedText(
                    'shop_tax',
                    defaultText: 'Tax',
                  ),
                  value: formatMoney(cart.tax),
                ),
                const SizedBox(height: 12),
                _Total(
                  label: const TranslatedText(
                    'shop_total',
                    defaultText: 'Total',
                  ),
                  value: formatMoney(cart.total),
                  bold: true,
                ),
              ],
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TranslatedText(
              'shop_cart_empty',
              defaultText: 'Your cart is empty',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.navigator.catalog().go(),
              child: const TranslatedText(
                'shop_browse_products',
                defaultText: 'Browse products',
              ),
            ),
          ],
        ),
      );
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final bool bold;
  final Widget label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            label,
            Text(value,
                style:
                    bold ? const TextStyle(fontWeight: FontWeight.w600) : null),
          ],
        ),
      );
}
