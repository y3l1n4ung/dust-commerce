import 'package:commerce_app/commerce_app.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Three-column collapsed address summary from the Medusa checkout.
final class CheckoutAddressSummary extends StatelessWidget {
  /// Creates the retained address summary.
  const CheckoutAddressSummary({required this.state, super.key});

  /// Address and contact values accepted in the first step.
  final CheckoutState state;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 32,
        runSpacing: 24,
        children: [
          _SummaryColumn(
            title: context.tr(
              'shop_checkout_shipping_address',
              defaultText: 'Shipping Address',
            ),
            lines: _addressLines(state.shipping),
          ),
          _SummaryColumn(
            title: context.tr('shop_checkout_contact', defaultText: 'Contact'),
            lines: [state.shipping.phone, state.email],
          ),
          _SummaryColumn(
            title: context.tr(
              'shop_checkout_billing_address',
              defaultText: 'Billing Address',
            ),
            lines: state.sameAsBilling
                ? [
                    context.tr(
                      'shop_checkout_same_billing_summary',
                      defaultText: 'Billing and delivery address are the same.',
                    ),
                  ]
                : _addressLines(state.billing),
          ),
        ],
      );

  static List<String> _addressLines(CheckoutAddressDraft value) => [
        '${value.firstName} ${value.lastName}',
        [value.line1, value.line2].where((part) => part.isNotEmpty).join(', '),
        '${value.postalCode}, ${value.city}',
        value.countryCode.toUpperCase(),
      ];
}

final class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({required this.title, required this.lines});

  final List<String> lines;
  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final line in lines.where((line) => line.isNotEmpty))
              Text(line,
                  style: const TextStyle(
                    color: StoreColors.foregroundSubtle,
                  )),
          ],
        ),
      );
}
