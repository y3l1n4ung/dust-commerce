import 'package:commerce_app/commerce_app.dart';
import 'package:flutter/material.dart';

import 'checkout_address_section.dart';
import 'checkout_delivery_section.dart';
import 'checkout_payment_section.dart';
import 'checkout_review_section.dart';
import 'checkout_summary.dart';

/// Responsive source checkout grid: form plus a 416px summary.
final class CheckoutLayout extends StatelessWidget {
  /// Creates the checkout layout.
  const CheckoutLayout({
    required this.step,
    required this.checkout,
    required this.cart,
    super.key,
  });

  /// Server-authoritative cart rendered by the summary.
  final CartState cart;

  /// Retained checkout workflow state.
  final CheckoutState checkout;

  /// Active source-compatible query step.
  final String step;

  @override
  Widget build(BuildContext context) {
    final view = cart.cart!;
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckoutAddressSection(
          open: step == 'address',
          state: checkout,
          countries: view.cart.region.countries,
        ),
        CheckoutDeliverySection(
          open: step == 'delivery',
          state: checkout,
          cart: cart,
        ),
        CheckoutPaymentSection(
          open: step == 'payment',
          state: checkout,
        ),
        CheckoutReviewSection(open: step == 'review', state: checkout),
      ],
    );
    final summary = CheckoutSummary(view: view, state: cart);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: MediaQuery.sizeOf(context).width >= 1024
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: form),
                      const SizedBox(width: 160),
                      SizedBox(width: 416, child: summary),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [form, const SizedBox(height: 48), summary],
                  ),
          ),
        ),
      ),
    );
  }
}
