import 'package:commerce_app/commerce_app.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'customer_address_controllers.dart';

/// Medusa-shaped customer-address fields shared by profile and address book.
final class CustomerAddressForm extends StatelessWidget {
  /// Creates address fields bound to [controllers].
  const CustomerAddressForm({
    required this.controllers,
    required this.countries,
    super.key,
  });

  /// Active region country codes returned by the store API.
  final List<String> countries;

  /// Controllers that own this form's text.
  final CustomerAddressControllers controllers;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _pair(
            context,
            _field(
              context,
              controllers.firstName,
              context.tr('shop_account_first_name', defaultText: 'First name'),
              autofillHints: const [AutofillHints.givenName],
            ),
            _field(
              context,
              controllers.lastName,
              context.tr('shop_account_last_name', defaultText: 'Last name'),
              autofillHints: const [AutofillHints.familyName],
            ),
          ),
          const SizedBox(height: 8),
          _field(
            context,
            controllers.company,
            context.tr('shop_account_company', defaultText: 'Company'),
            required: false,
            autofillHints: const [AutofillHints.organizationName],
          ),
          const SizedBox(height: 8),
          _field(
            context,
            controllers.line1,
            context.tr('shop_account_address', defaultText: 'Address'),
            autofillHints: const [AutofillHints.streetAddressLine1],
          ),
          const SizedBox(height: 8),
          _field(
            context,
            controllers.line2,
            context.tr(
              'shop_account_address_line_2',
              defaultText: 'Apartment, suite, etc.',
            ),
            required: false,
            autofillHints: const [AutofillHints.streetAddressLine2],
          ),
          const SizedBox(height: 8),
          _pair(
            context,
            _field(
              context,
              controllers.postalCode,
              context.tr('shop_account_postal_code',
                  defaultText: 'Postal code'),
              autofillHints: const [AutofillHints.postalCode],
            ),
            _field(
              context,
              controllers.city,
              context.tr('shop_account_city', defaultText: 'City'),
              autofillHints: const [AutofillHints.addressCity],
            ),
          ),
          const SizedBox(height: 8),
          _field(
            context,
            controllers.province,
            context.tr('shop_account_province',
                defaultText: 'Province / State'),
            required: false,
            autofillHints: const [AutofillHints.addressState],
          ),
          const SizedBox(height: 8),
          _country(context),
          const SizedBox(height: 8),
          _field(
            context,
            controllers.phone,
            context.tr('shop_account_phone', defaultText: 'Phone'),
            required: false,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
        ],
      );

  Widget _pair(BuildContext context, Widget first, Widget second) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(children: [first, const SizedBox(height: 8), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 8),
            Expanded(child: second),
          ],
        );
      });

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        validator: required ? (value) => _required(context, value) : null,
        decoration: _decoration(required ? '$label *' : label),
      );

  Widget _country(BuildContext context) {
    final current = controllers.countryCode.text;
    final options = <String>{...countries, if (current.isNotEmpty) current};
    return DropdownButtonFormField<String>(
      initialValue:
          options.contains(current) && current.isNotEmpty ? current : null,
      items: [
        for (final country in options)
          DropdownMenuItem(value: country, child: Text(country.toUpperCase())),
      ],
      onChanged: countries.isEmpty
          ? null
          : (value) => controllers.countryCode.text = value ?? '',
      validator: (value) => _required(context, value),
      decoration: _decoration(
        '${context.tr('shop_account_country', defaultText: 'Country')} *',
      ),
    );
  }

  String? _required(BuildContext context, String? value) =>
      value == null || value.trim().isEmpty
          ? context.tr(
              'shop_account_required',
              defaultText: 'This field is required.',
            )
          : null;

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
