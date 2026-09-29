import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Source-spaced control for reusing the shipping destination for billing.
final class CheckoutBillingToggle extends StatelessWidget {
  /// Creates the billing-address toggle.
  const CheckoutBillingToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Receives the next checked state.
  final ValueChanged<bool> onChanged;

  /// Whether the shipping destination is reused.
  final bool value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: Checkbox(
                value: value,
                onChanged: (next) => onChanged(next ?? true),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: TranslatedText(
                'shop_checkout_same_billing',
                defaultText: 'Billing address same as shipping address',
              ),
            ),
          ],
        ),
      );
}
