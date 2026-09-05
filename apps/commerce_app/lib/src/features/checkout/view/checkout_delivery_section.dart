import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'checkout_step_header.dart';

/// Server-priced delivery choice translated from Medusa Shipping.
final class CheckoutDeliverySection extends StatelessWidget {
  /// Creates the delivery step.
  const CheckoutDeliverySection({
    required this.open,
    required this.state,
    required this.cart,
    super.key,
  });

  /// Current server-authoritative cart and shipping choices.
  final CartState cart;

  /// Whether delivery choices are expanded.
  final bool open;

  /// Checkout operation state.
  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final selected = cart.cart?.cart.shippingMethod;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckoutStepHeader(
          title: context.tr('shop_checkout_delivery', defaultText: 'Delivery'),
          open: open,
          complete: selected != null,
          onEdit: () => context.pushCheckoutStep('delivery'),
        ),
        if (open) _choices(context, selected) else _summary(selected),
        const CheckoutSectionDivider(),
      ],
    );
  }

  Widget _choices(BuildContext context, ShippingMethod? selected) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TranslatedText('shop_checkout_shipping_method',
              defaultText: 'Shipping method',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const TranslatedText(
            'shop_checkout_delivery_prompt',
            defaultText: 'How would you like your order delivered',
            style: TextStyle(color: StoreColors.foregroundMuted),
          ),
          const SizedBox(height: 16),
          if (cart.shippingOptions.isEmpty && state.isBusy)
            const Center(child: CircularProgressIndicator())
          else
            for (final option in cart.shippingOptions) ...[
              _DeliveryChoice(
                option: option,
                selected: selected?.optionId == option.optionId,
                enabled: !state.isBusy,
                onTap: () => context
                    .readCheckoutViewModel()
                    .chooseDelivery(option.optionId),
              ),
              const SizedBox(height: 8),
            ],
          if (state.status == CheckoutStatus.failed &&
              state.operation == CheckoutOperation.delivery) ...[
            const SizedBox(height: 8),
            Text(state.message!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: state.isBusy
                    ? null
                    : context.readCheckoutViewModel().loadDelivery,
                child: const TranslatedText(
                  'shop_retry',
                  defaultText: 'Try again',
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: selected == null || state.isBusy
                  ? null
                  : () => context.pushCheckoutStep('payment'),
              child: const TranslatedText(
                'shop_checkout_continue_payment',
                defaultText: 'Continue to payment',
              ),
            ),
          ),
        ],
      );

  Widget _summary(ShippingMethod? selected) => selected == null
      ? const SizedBox.shrink()
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TranslatedText(
              'shop_checkout_method',
              defaultText: 'Method',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${selected.name} ${formatMoney(selected.amount)}',
              style: const TextStyle(color: StoreColors.foregroundSubtle),
            ),
          ],
        );
}

final class _DeliveryChoice extends StatelessWidget {
  const _DeliveryChoice({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;
  final ShippingMethod option;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
        color: StoreColors.base,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? StoreColors.interactive : StoreColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected
                      ? StoreColors.interactive
                      : StoreColors.foregroundMuted,
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(option.name)),
                Text(formatMoney(option.amount)),
              ],
            ),
          ),
        ),
      );
}
