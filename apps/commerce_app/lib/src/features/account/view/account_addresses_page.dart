import 'dart:async';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'account_route_layout.dart';
import 'account_section.dart';
import 'add_address_card.dart';
import 'address_editor_dialog.dart';
import 'customer_address_card.dart';

/// Authenticated Medusa shipping-address route.
@AppRoute('/account/addresses',
    name: 'accountAddresses', guards: [CustomerGuard])
final class AccountAddressesPage extends StatefulWidget {
  /// Creates the address-book page.
  const AccountAddressesPage({super.key});

  @override
  State<AccountAddressesPage> createState() => _AccountAddressesPageState();
}

class _AccountAddressesPageState extends State<AccountAddressesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final addresses = context.readAddressBookViewModel();
      if (addresses.state.status == AddressBookStatus.idle) {
        unawaited(addresses.load());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watchAccountViewModel().value;
    final addresses = context.watchAddressBookViewModel().value;
    final customer = account.customer;
    return StoreScaffold(
      body: customer == null
          ? const Center(child: CircularProgressIndicator())
          : AccountRouteLayout(
              customer: customer,
              state: account,
              active: AccountSection.addresses,
              child: _AddressBookContent(
                customer: customer,
                state: addresses,
              ),
            ),
    );
  }
}

final class _AddressBookContent extends StatelessWidget {
  const _AddressBookContent({required this.customer, required this.state});

  final Customer customer;
  final AddressBookState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TranslatedText(
            'shop_account_shipping_addresses',
            defaultText: 'Shipping Addresses',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TranslatedText(
            'shop_account_addresses_body',
            defaultText: 'View and update your shipping addresses. Add as '
                'many as you like to make them available during checkout.',
          ),
          const SizedBox(height: 32),
          if (state.status == AddressBookStatus.loading &&
              state.addresses.isEmpty)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (state.status == AddressBookStatus.failed) ...[
              _AddressFailure(state: state),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 720;
                final width = twoColumns
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: AddAddressCard(
                        enabled: state.countries.isNotEmpty && !state.isBusy,
                        onTap: () => _openEditor(context),
                      ),
                    ),
                    for (final address in state.addresses)
                      SizedBox(
                        width: width,
                        child: CustomerAddressCard(
                          address: address,
                          busy: state.isBusy,
                          onEdit: () => _openEditor(context, address),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      );

  void _openEditor(BuildContext context, [CustomerAddressView? address]) {
    unawaited(showDialog<void>(
      context: context,
      builder: (_) => AddressEditorDialog(
        customer: customer,
        countries: state.countries,
        hasDefaultShipping:
            state.addresses.any((item) => item.isDefaultShipping),
        address: address,
      ),
    ));
  }
}

final class _AddressFailure extends StatelessWidget {
  const _AddressFailure({required this.state});

  final AddressBookState state;

  @override
  Widget build(BuildContext context) {
    final message = switch (state.message) {
      Some(:final value) => value,
      None() => context.tr(
          'shop_account_address_error',
          defaultText: 'We could not load your address book.',
        ),
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xffe11d48)),
          ),
        ),
        if (state.addresses.isEmpty)
          OutlinedButton(
            onPressed: context.readAddressBookViewModel().load,
            child: TranslatedText('shop_retry', defaultText: 'Try again'),
          ),
      ],
    );
  }
}
