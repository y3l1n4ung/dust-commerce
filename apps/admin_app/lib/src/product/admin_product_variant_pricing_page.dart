import 'package:admin_app/src/core/admin_money.dart';
import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

part 'admin_product_variant_pricing_fields.dart';

/// Opens Medusa's full-screen variant-pricing focus surface.
Future<bool?> showAdminProductVariantPricingPage(
  BuildContext context,
  AdminProductDetail product,
  AdminProductVariant variant,
) async {
  final currencies =
      await context.readAdminProductDetailViewModel().pricingCurrencies();
  if (!context.mounted) return null;
  return switch (currencies) {
    Some(value: final values) => showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Close price editor',
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (_, __, ___) => _VariantPricingPage(
          product: product,
          variant: variant,
          currencies: values,
        ),
      ),
    None() => null,
  };
}

final class _VariantPricingPage extends StatefulWidget {
  const _VariantPricingPage({
    required this.product,
    required this.variant,
    required this.currencies,
  });

  final List<String> currencies;
  final AdminProductDetail product;
  final AdminProductVariant variant;

  @override
  State<_VariantPricingPage> createState() => _VariantPricingPageState();
}

final class _VariantPricingPageState extends State<_VariantPricingPage> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _prices;

  @override
  void initState() {
    super.initState();
    final current = {
      for (final price in widget.variant.prices)
        price.currencyCode: price.amount,
    };
    _prices = {
      for (final currency in widget.currencies)
        currency: TextEditingController(
          text: switch (current[currency]) {
            final amount? => formatMinorUnits(amount, currency),
            null => '',
          },
        ),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readAdminProductDetailViewModel().clearFailure();
    });
  }

  @override
  void dispose() {
    for (final controller in _prices.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductDetailViewModel().value;
    final busy = state.isSaving;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _header(busy),
            Expanded(child: _body(state, busy)),
            _footer(busy),
          ],
        ),
      ),
    );
  }

  Widget _header(bool busy) => Container(
        height: 56,
        padding: const EdgeInsets.only(left: 24, right: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Text(
              'Edit prices',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Close',
              onPressed: busy ? null : () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      );

  Widget _footer(bool busy) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: busy ? null : _save,
              child: busy
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      );
}
