import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'checkout_address_controllers.dart';
import 'checkout_address_fields.dart';

/// Contact row that follows Medusa's billing-address checkbox.
final class CheckoutContactFields extends StatelessWidget {
  /// Creates the email and optional phone inputs.
  const CheckoutContactFields({
    required this.controllers,
    required this.email,
    super.key,
  });

  /// Shipping-address controllers own the courier phone value.
  final CheckoutAddressControllers controllers;

  /// Checkout receipt email controller.
  final TextEditingController email;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _field(
              context,
              email,
              context.tr('shop_checkout_email', defaultText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _field(
              context,
              controllers.phone,
              context.tr('shop_checkout_phone', defaultText: 'Phone'),
              keyboardType: TextInputType.phone,
              required: false,
            ),
          ),
        ],
      );

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: checkoutFieldTextStyle,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? context.tr(
                    'shop_checkout_required',
                    defaultText: 'This field is required.',
                  )
                : null
            : null,
        decoration: checkoutFieldDecoration(label, required: required),
      );
}
