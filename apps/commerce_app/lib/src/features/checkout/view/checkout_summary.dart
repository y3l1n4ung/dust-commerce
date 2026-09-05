import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import '../../cart/view/promotion_code.dart';

/// Sticky desktop checkout summary translated from Medusa CheckoutSummary.
final class CheckoutSummary extends StatelessWidget {
  /// Creates a checkout summary from authoritative cart totals.
  const CheckoutSummary({required this.view, required this.state, super.key});

  /// Mutation state used by the promotion control.
  final CartState state;

  /// Authoritative cart totals and lines.
  final CartView view;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TranslatedText(
            'shop_checkout_in_cart',
            defaultText: 'In your Cart',
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _CheckoutTotals(view: view),
          const SizedBox(height: 24),
          for (final item in view.cart.items) ...[
            _CheckoutLine(item: item),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          PromotionCode(cart: view.cart, state: state),
        ],
      );
}

final class _CheckoutLine extends StatelessWidget {
  const _CheckoutLine({required this.item});

  final LineItem item;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox.square(
            dimension: 64,
            child: ProductImage(url: item.thumbnail, aspectRatio: 1),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.variantTitle case final title?)
                  Text(
                    title,
                    style: const TextStyle(color: StoreColors.foregroundSubtle),
                  ),
                Text(
                  context.tr(
                    'shop_checkout_quantity',
                    defaultText: 'Quantity: {count}',
                    args: {'count': item.quantity},
                  ),
                  style: const TextStyle(color: StoreColors.foregroundSubtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(formatMoney(item.subtotal)),
        ],
      );
}

final class _CheckoutTotals extends StatelessWidget {
  const _CheckoutTotals({required this.view});

  final CartView view;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _row(context.tr('shop_checkout_subtotal', defaultText: 'Subtotal'),
              view.subtotal),
          _row(context.tr('shop_checkout_shipping', defaultText: 'Shipping'),
              view.shippingTotal),
          if (!view.discountTotal.isZero)
            _row(context.tr('shop_checkout_discount', defaultText: 'Discount'),
                view.discountTotal,
                discount: true),
          _row(context.tr('shop_checkout_taxes', defaultText: 'Taxes'),
              view.tax),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _row(context.tr('shop_checkout_total', defaultText: 'Total'),
              view.total,
              strong: true),
        ],
      );

  Widget _row(
    String label,
    Money money, {
    bool discount = false,
    bool strong = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                  color: StoreColors.foregroundSubtle,
                  fontWeight: strong ? FontWeight.w600 : null,
                )),
            Text(
              '${discount ? '- ' : ''}${formatMoney(money)}',
              style: TextStyle(
                color:
                    discount ? StoreColors.interactive : StoreColors.foreground,
                fontWeight: strong ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      );
}
