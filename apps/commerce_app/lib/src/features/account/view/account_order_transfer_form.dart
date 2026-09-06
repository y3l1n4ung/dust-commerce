import 'dart:async';

import 'package:commerce_app/commerce_app.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'account_order_transfer_success.dart';

/// Source-shaped form for connecting an existing order to this account.
final class AccountOrderTransferForm extends StatefulWidget {
  /// Creates the order-transfer request form.
  const AccountOrderTransferForm({super.key});

  @override
  State<AccountOrderTransferForm> createState() =>
      _AccountOrderTransferFormState();
}

final class _AccountOrderTransferFormState
    extends State<AccountOrderTransferForm> {
  final _form = GlobalKey<FormState>();
  final _orderId = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readOrderTransferViewModel().reset();
    });
  }

  @override
  void dispose() {
    _orderId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchOrderTransferViewModel().value;
    final desktop = MediaQuery.sizeOf(context).width >= 1024;
    final intro = _intro(context);
    final form = _requestForm(context, state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: intro),
              const SizedBox(width: 32),
              Expanded(child: form),
            ],
          )
        else ...[
          intro,
          const SizedBox(height: 16),
          form,
        ],
        if (state.status == OrderTransferActionStatus.failed) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              orderTransferFailureMessage(context, state.failure),
              textAlign: TextAlign.right,
              style: const TextStyle(color: StoreColors.rose),
            ),
          ),
        ],
        if (state.status == OrderTransferActionStatus.succeeded) ...[
          const SizedBox(height: 16),
          AccountOrderTransferSuccess(
            state: state,
            fallbackOrderId: _orderId.text.trim(),
          ),
        ],
      ],
    );
  }

  Widget _intro(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            'shop_account_order_transfers',
            defaultText: 'Order transfers',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          TranslatedText(
            'shop_account_order_transfers_body',
            defaultText: "Can't find the order you are looking for?\n"
                'Connect an order to your account.',
            style: TextStyle(color: StoreColors.foregroundMuted),
          ),
        ],
      );

  Widget _requestForm(BuildContext context, OrderTransferState state) {
    final busy = state.status == OrderTransferActionStatus.pending;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: _orderId,
            enabled: !busy,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!busy) _submit();
            },
            validator: (value) => value == null || value.trim().isEmpty
                ? context.tr(
                    'shop_account_order_id_required',
                    defaultText: 'Order ID is required',
                  )
                : null,
            decoration: InputDecoration(
              hintText: context.tr(
                'shop_account_order_id',
                defaultText: 'Order ID',
              ),
              filled: true,
              fillColor: StoreColors.subtle,
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: StoreColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const TranslatedText(
                    'shop_account_request_transfer',
                    defaultText: 'Request transfer',
                  ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    unawaited(context.readOrderTransferViewModel().request(_orderId.text));
  }
}
