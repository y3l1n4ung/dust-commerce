import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Greeting and source-shaped selector for usable saved addresses.
final class CheckoutSavedAddressContent extends StatelessWidget {
  /// Creates saved-address content.
  const CheckoutSavedAddressContent({
    required this.addresses,
    required this.customer,
    required this.draft,
    required this.onSelected,
    super.key,
  });

  /// Region-compatible customer addresses.
  final List<CustomerAddressView> addresses;

  /// Customer named in the greeting.
  final Customer customer;

  /// Current form values used to mark the selected address.
  final CheckoutAddressDraft draft;

  /// Copies one address into the form.
  final ValueChanged<CustomerAddressView> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = addresses
        .where(draft.matchesSavedAddress)
        .map((address) => address.id)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(
          'shop_checkout_saved_address_prompt',
          defaultText:
              'Hi {name}, do you want to use one of your saved addresses?',
          args: {'name': _greetingName},
        )),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey(selected),
          initialValue: selected,
          isExpanded: true,
          itemHeight: null,
          menuMaxHeight: 320,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: StoreColors.border),
            ),
          ),
          hint: TranslatedText(
            'shop_checkout_choose_saved_address',
            defaultText: 'Choose an address',
          ),
          selectedItemBuilder: (_) => [
            for (final address in addresses)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  address.line1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          items: [
            for (final address in addresses)
              DropdownMenuItem(
                value: address.id,
                child: _SavedAddressOption(
                  address: address,
                  selected: address.id == selected,
                ),
              ),
          ],
          onChanged: (id) {
            for (final address in addresses) {
              if (address.id == id) return onSelected(address);
            }
          },
        ),
      ],
    );
  }

  String get _greetingName {
    final firstName = customer.firstName?.trim();
    return firstName == null || firstName.isEmpty
        ? customer.displayName
        : firstName;
  }
}

final class _SavedAddressOption extends StatelessWidget {
  const _SavedAddressOption({required this.address, required this.selected});

  final CustomerAddressView address;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${address.firstName} ${address.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (address.company case final company?) Text(company),
                  Text('${address.line1}${_line2(address.line2)}'),
                  Text('${address.postalCode}, ${address.city}'),
                  Text(
                    '${_province(address.province)}'
                    '${address.countryCode.toUpperCase()}',
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  static String _line2(String? value) => value == null ? '' : ', $value';

  static String _province(String? value) => value == null ? '' : '$value, ';
}
