import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'checkout_step_header.dart';

/// Region-backed provider choices translated from Medusa Payment.
final class CheckoutPaymentSection extends StatelessWidget {
  /// Creates the payment step.
  const CheckoutPaymentSection({
    required this.open,
    required this.state,
    super.key,
  });

  /// Whether payment selection is expanded.
  final bool open;

  /// Retained payment selection and progress.
  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.hasPaymentMethod;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckoutStepHeader(
          title: context.tr('shop_checkout_payment', defaultText: 'Payment'),
          open: open,
          complete: selected,
          onEdit: () => context.pushCheckoutStep('payment'),
        ),
        if (open) _choices(context) else if (selected) _summary(context),
        const CheckoutSectionDivider(),
      ],
    );
  }

  Widget _choices(BuildContext context) => Column(
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
              _providerChoice(context, provider),
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

  Widget _providerChoice(
    BuildContext context,
    PaymentProviderView provider,
  ) {
    final selected = state.isPaymentSelected(provider.id);
    return Material(
      color: StoreColors.base,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? StoreColors.interactive : StoreColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: state.isBusy
            ? null
            : () => context.readCheckoutViewModel().selectPayment(provider.id),
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
              Expanded(child: _providerTitle(provider.id)),
              const Icon(Icons.credit_card, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PaymentSummary(
              title: context.tr(
                'shop_checkout_payment_method',
                defaultText: 'Payment method',
              ),
              child: state.paymentMethod.match(
                some: _providerTitle,
                none: () => const SizedBox.shrink(),
              ),
            ),
          ),
          Expanded(
            child: _PaymentSummary(
              title: context.tr(
                'shop_checkout_payment_details',
                defaultText: 'Payment details',
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: TranslatedText(
                      'shop_checkout_payment_next_step',
                      defaultText: 'Another step will appear',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _providerTitle(String id) => id == 'manual'
      ? const TranslatedText(
          'shop_checkout_manual_payment',
          defaultText: 'Manual Payment',
        )
      : Text(id);
}

final class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.title, required this.child});

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DefaultTextStyle.merge(
            style: const TextStyle(color: StoreColors.foregroundSubtle),
            child: child,
          ),
        ],
      );
}
