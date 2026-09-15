import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'checkout_payment_summary.dart';

/// Expanded region-backed payment choices and progression action.
final class CheckoutPaymentChoices extends StatelessWidget {
  /// Creates the payment-choice list.
  const CheckoutPaymentChoices({required this.state, super.key});

  /// Retained provider selection and request state.
  final CheckoutState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!state.paymentProvidersLoaded && state.isBusy)
            const Center(child: CircularProgressIndicator())
          else if (!state.paymentProvidersLoaded) ...[
            if (state.message != null)
              Text(state.message!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () =>
                    context.readCheckoutViewModel().loadPaymentMethods(),
                child: const TranslatedText(
                  'shop_checkout_retry_payment_methods',
                  defaultText: 'Retry payment methods',
                ),
              ),
            ),
          ] else if (state.paymentProviders.isEmpty)
            const TranslatedText(
              'shop_checkout_no_payment_methods',
              defaultText: 'No payment methods are available.',
            )
          else ...[
            for (final provider in state.paymentProviders) ...[
              _PaymentProviderChoice(
                provider: provider,
                selected: state.isPaymentSelected(provider.id),
                enabled: !state.isBusy,
              ),
              const SizedBox(height: 8),
            ],
            if (state.message != null)
              Text(state.message!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: state.hasAvailablePaymentMethod && !state.isBusy
                      ? () => context.pushCheckoutStep('review')
                      : null,
                  child: const TranslatedText(
                    'shop_checkout_continue_review',
                    defaultText: 'Continue to review',
                  ),
                ),
              ),
            ),
          ],
        ],
      );
}

final class _PaymentProviderChoice extends StatelessWidget {
  const _PaymentProviderChoice({
    required this.provider,
    required this.selected,
    required this.enabled,
  });

  final bool enabled;
  final PaymentProviderView provider;
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
          onTap: enabled
              ? () => context.readCheckoutViewModel().selectPayment(provider.id)
              : null,
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
                Expanded(child: PaymentProviderTitle(id: provider.id)),
                const Icon(Icons.credit_card, size: 20),
              ],
            ),
          ),
        ),
      );
}
