import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Expanded server-priced delivery choices and progression action.
final class CheckoutDeliveryChoices extends StatelessWidget {
  /// Creates the delivery-choice list.
  const CheckoutDeliveryChoices({
    required this.cart,
    required this.selected,
    required this.state,
    super.key,
  });

  /// Current server-authoritative cart and shipping choices.
  final CartState cart;

  /// Shipping method selected on the cart.
  final ShippingMethod? selected;

  /// Checkout operation state.
  final CheckoutState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TranslatedText(
            'shop_checkout_shipping_method',
            defaultText: 'Shipping method',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
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
                available: option.isAvailableFor(cart.cart!.subtotal),
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
}

/// Collapsed delivery method accepted by the server-owned cart.
final class CheckoutDeliverySummary extends StatelessWidget {
  /// Creates a delivery summary.
  const CheckoutDeliverySummary({required this.selected, super.key});

  /// Shipping method selected on the cart.
  final ShippingMethod? selected;

  @override
  Widget build(BuildContext context) {
    final method = selected;
    if (method == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'shop_checkout_method',
          defaultText: 'Method',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          '${method.name} ${formatMoney(method.amount)}',
          style: const TextStyle(color: StoreColors.foregroundSubtle),
        ),
      ],
    );
  }
}

final class _DeliveryChoice extends StatelessWidget {
  const _DeliveryChoice({
    required this.option,
    required this.selected,
    required this.available,
    required this.enabled,
    required this.onTap,
  });

  final bool available;
  final bool enabled;
  final VoidCallback onTap;
  final ShippingOption option;
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
          onTap: enabled && available ? onTap : null,
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
                  color: !available
                      ? StoreColors.foregroundDisabled
                      : selected
                          ? StoreColors.interactive
                          : StoreColors.foregroundMuted,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option.name,
                    style: TextStyle(
                      color: available
                          ? StoreColors.foreground
                          : StoreColors.foregroundDisabled,
                    ),
                  ),
                ),
                Text(available ? formatMoney(option.amount) : '-'),
              ],
            ),
          ),
        ),
      );
}
