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
    this.includeContact = false,
    this.email,
    super.key,
  });

  /// Region country codes offered by the server.
  final List<String> countries;

  /// Controllers for this address block.
  final CheckoutAddressControllers controllers;

  /// Contact email controller when [includeContact] is true.
  final TextEditingController? email;

  /// Whether email and phone fields follow the address grid.
  final bool includeContact;

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
          const SizedBox(height: 12),
          _row(
            _field(context, controllers.line1,
                context.tr('shop_checkout_address', defaultText: 'Address')),
            _field(
              context,
              controllers.line2,
              context.tr('shop_checkout_address_line_2',
                  defaultText: 'Apartment / Company'),
              required: false,
            ),
          ),
          const SizedBox(height: 12),
          _row(
            _field(
                context,
                controllers.postalCode,
                context.tr('shop_checkout_postal_code',
                    defaultText: 'Postal code')),
            _field(context, controllers.city,
                context.tr('shop_checkout_city', defaultText: 'City')),
          ),
          const SizedBox(height: 12),
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
          if (includeContact) ...[
            const SizedBox(height: 16),
            _row(
              _field(context, email!,
                  context.tr('shop_checkout_email', defaultText: 'Email'),
                  keyboardType: TextInputType.emailAddress),
              _field(context, controllers.phone,
                  context.tr('shop_checkout_phone', defaultText: 'Phone'),
                  keyboardType: TextInputType.phone, required: false),
            ),
          ],
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
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? context.tr(
                    'shop_checkout_required',
                    defaultText: 'This field is required.',
                  )
                : null
            : null,
        decoration: _decoration(required ? '$label *' : label),
      );

  Widget _country(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: countries.contains(controllers.countryCode.text)
            ? controllers.countryCode.text
            : null,
        items: [
          for (final country in countries)
            DropdownMenuItem(
              value: country,
              child: Text(country.toUpperCase()),
            ),
        ],
        onChanged: (value) => controllers.countryCode.text = value ?? '',
        validator: (value) => value == null
            ? context.tr(
                'shop_checkout_choose_country',
                defaultText: 'Choose a country.',
              )
            : null,
        decoration: _decoration(
          '${context.tr('shop_checkout_country', defaultText: 'Country')} *',
        ),
      );

  static InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: StoreColors.subtle,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: StoreColors.border),
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      );
}
