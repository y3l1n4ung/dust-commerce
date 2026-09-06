import 'package:commerce_app/commerce_app.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'checkout_address_controllers.dart';

/// The field grid shared by shipping and separate billing addresses.
final class CheckoutAddressFields extends StatelessWidget {
  /// Creates address fields bound to [controllers].
  const CheckoutAddressFields({
    required this.controllers,
    required this.countries,
    super.key,
  });

  /// Region country codes offered by the server.
  final List<String> countries;

  /// Controllers for this address block.
  final CheckoutAddressControllers controllers;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _row(
            _field(
                context,
                controllers.firstName,
                context.tr('shop_checkout_first_name',
                    defaultText: 'First name')),
            _field(
                context,
                controllers.lastName,
                context.tr('shop_checkout_last_name',
                    defaultText: 'Last name')),
          ),
          const SizedBox(height: 14),
          _row(
            _field(context, controllers.line1,
                context.tr('shop_checkout_address', defaultText: 'Address')),
            _field(
              context,
              controllers.company,
              context.tr('shop_checkout_company', defaultText: 'Company'),
              required: false,
            ),
          ),
          const SizedBox(height: 14),
          _row(
            _field(
                context,
                controllers.postalCode,
                context.tr('shop_checkout_postal_code',
                    defaultText: 'Postal code')),
            _field(context, controllers.city,
                context.tr('shop_checkout_city', defaultText: 'City')),
          ),
          const SizedBox(height: 14),
          _row(
            _country(context),
            _field(
              context,
              controllers.province,
              context.tr('shop_checkout_province',
                  defaultText: 'State / Province'),
              required: false,
            ),
          ),
        ],
      );

  Widget _row(Widget left, Widget right) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
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

  Widget _country(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: countries.contains(controllers.countryCode.text)
            ? controllers.countryCode.text
            : null,
        icon: const Icon(Icons.unfold_more, size: 16),
        style: checkoutFieldTextStyle,
        items: [
          for (final country in countries)
            DropdownMenuItem(
              value: country,
              child: Text(countryName(context, country)),
            ),
        ],
        onChanged: (value) => controllers.countryCode.text = value ?? '',
        validator: (value) => value == null
            ? context.tr(
                'shop_checkout_choose_country',
                defaultText: 'Choose a country.',
              )
            : null,
        hint: Text(
          context.tr('shop_checkout_country', defaultText: 'Country'),
        ),
        decoration: checkoutFieldDecoration(null),
      );
}

/// Source-shaped 44px checkout input decoration shared with contact fields.
InputDecoration checkoutFieldDecoration(
  String? label, {
  bool required = false,
}) =>
    InputDecoration(
      label: label == null
          ? null
          : Text.rich(TextSpan(children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: '*',
                  style: TextStyle(color: StoreColors.rose),
                ),
            ])),
      filled: true,
      fillColor: StoreColors.subtle,
      isDense: true,
      constraints: const BoxConstraints(minHeight: 44),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: StoreColors.border),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    );

/// Source `txt-compact-medium` size used inside checkout form controls.
const checkoutFieldTextStyle = TextStyle(fontSize: 14, height: 20 / 14);
