import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'checkout_address_fields.dart';
import 'checkout_address_controllers.dart';
import 'checkout_address_summary.dart';
import 'checkout_saved_address_selector.dart';
import 'checkout_step_header.dart';

/// Shipping and optional billing form translated from Medusa Addresses.
final class CheckoutAddressSection extends StatefulWidget {
  /// Creates the address step.
  const CheckoutAddressSection({
    required this.open,
    required this.state,
    required this.countries,
    required this.customer,
    required this.addressBook,
    super.key,
  });

  /// Current authenticated customer's separately loaded address book.
  final AddressBookState addressBook;

  /// Region countries available in the address select.
  final List<String> countries;

  /// Server-proven customer, absent for guest checkout.
  final Customer? customer;

  /// Whether the address form is expanded.
  final bool open;

  /// Retained checkout input and operation state.
  final CheckoutState state;

  @override
  State<CheckoutAddressSection> createState() => _CheckoutAddressSectionState();
}

class _CheckoutAddressSectionState extends State<CheckoutAddressSection> {
  final _form = GlobalKey<FormState>();
  late final CheckoutAddressControllers _shipping;
  late final CheckoutAddressControllers _billing;
  late final TextEditingController _email;
  late bool _sameAsBilling;

  @override
  void initState() {
    super.initState();
    _shipping = CheckoutAddressControllers(widget.state.shipping);
    _billing = CheckoutAddressControllers(widget.state.billing);
    _email = TextEditingController(text: widget.state.email);
    _sameAsBilling = widget.state.sameAsBilling;
  }

  @override
  void dispose() {
    _shipping.dispose();
    _billing.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckoutStepHeader(
            title: context.tr(
              'shop_checkout_shipping_address',
              defaultText: 'Shipping Address',
            ),
            open: widget.open,
            complete: widget.state.shipping.firstName.isNotEmpty,
            onEdit: () => context.pushCheckoutStep('address'),
          ),
          if (widget.open)
            _formBody()
          else
            CheckoutAddressSummary(state: widget.state),
          const CheckoutSectionDivider(),
        ],
      );

  Widget _formBody() => Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.customer case final customer?) ...[
              CheckoutSavedAddressSelector(
                customer: customer,
                state: widget.addressBook,
                countries: widget.countries,
                draft: _shipping.draft,
                onSelected: _selectSavedAddress,
              ),
              if (widget.addressBook.status != AddressBookStatus.ready ||
                  widget.addressBook
                      .shippingAddressesFor(widget.countries)
                      .isNotEmpty)
                const SizedBox(height: 24),
            ],
            CheckoutAddressFields(
              controllers: _shipping,
              countries: widget.countries,
              includeContact: true,
              email: _email,
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _sameAsBilling,
              onChanged: (value) => setState(
                () => _sameAsBilling = value ?? true,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const TranslatedText(
                'shop_checkout_same_billing',
                defaultText: 'Billing address same as shipping address',
              ),
            ),
            if (!_sameAsBilling) ...[
              const SizedBox(height: 24),
              const TranslatedText(
                'shop_checkout_billing_address',
                defaultText: 'Billing address',
                style: TextStyle(fontSize: 30, height: 1.25),
              ),
              const SizedBox(height: 24),
              CheckoutAddressFields(
                controllers: _billing,
                countries: widget.countries,
              ),
            ],
            if (widget.state.status == CheckoutStatus.failed &&
                widget.state.operation == CheckoutOperation.prepare) ...[
              const SizedBox(height: 12),
              Text(widget.state.message!,
                  style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: widget.state.isBusy ? null : _continue,
                child: const TranslatedText(
                  'shop_checkout_continue_delivery',
                  defaultText: 'Continue to delivery',
                ),
              ),
            ),
          ],
        ),
      );

  void _selectSavedAddress(CustomerAddressView address) {
    _shipping.replace(CheckoutAddressDraft.fromSavedAddress(address));
    setState(() {});
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate()) return;
    final checkout = context.readCheckoutViewModel();
    final valid = checkout.saveAddresses(
      email: _email.text,
      shipping: _shipping.draft,
      billing: _billing.draft,
      sameAsBilling: _sameAsBilling,
    );
    if (!valid || !await checkout.loadDelivery() || !mounted) return;
    context.pushCheckoutStep('delivery');
  }
}
