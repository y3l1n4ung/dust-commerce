import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Medusa saved-address prompt adapted to the separately loaded address book.
final class CheckoutSavedAddressSelector extends StatelessWidget {
  /// Creates a region-scoped saved-address control.
  const CheckoutSavedAddressSelector({
    required this.customer,
    required this.state,
    required this.countries,
    required this.draft,
    required this.onSelected,
    super.key,
  });

  /// Region country codes accepted by this cart.
  final List<String> countries;

  /// Customer named in the source greeting.
  final Customer customer;

  /// Current editable shipping form used to identify the selected address.
  final CheckoutAddressDraft draft;

  /// Copies the selected saved address into the editable form.
  final ValueChanged<CustomerAddressView> onSelected;

  /// Address-book request and data state.
  final AddressBookState state;

  @override
  Widget build(BuildContext context) {
    final addresses = state.shippingAddressesFor(countries);
    if (addresses.isEmpty && state.status == AddressBookStatus.ready) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StoreColors.base,
        border: Border.all(color: StoreColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: switch (state.status) {
        AddressBookStatus.idle ||
        AddressBookStatus.loading =>
          const LinearProgressIndicator(minHeight: 2),
        AddressBookStatus.failed when addresses.isEmpty => _failure(context),
        _ => _selector(context, addresses),
      },
    );
  }

  Widget _selector(
    BuildContext context,
    List<CustomerAddressView> addresses,
  ) {
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

  Widget _failure(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              context.tr(
                'shop_checkout_saved_addresses_unavailable',
                defaultText:
                    'Saved addresses are unavailable. Enter one below.',
              ),
              style: const TextStyle(color: StoreColors.foregroundSubtle),
            ),
          ),
          TextButton(
            onPressed: context.readAddressBookViewModel().load,
            child: const TranslatedText('shop_retry', defaultText: 'Try again'),
          ),
        ],
      );

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
