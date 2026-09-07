part of 'admin_product_variant_pricing_page.dart';

extension on _VariantPricingPageState {
  Widget _body(AdminProductDetailState state, bool busy) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Variant prices',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set exact amounts for every active storefront currency.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      _priceGrid(busy),
                      if (state.failure case Some(value: final message)) ...[
                        const SizedBox(height: 16),
                        _failure(message),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _priceGrid(bool busy) => Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (320 + widget.currencies.length * 180)
                .clamp(680, 960)
                .toDouble(),
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  child: Row(
                    children: [
                      const Expanded(flex: 2, child: Text('Title')),
                      for (final currency in widget.currencies)
                        SizedBox(
                          width: 180,
                          child: Text(currency.toUpperCase()),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: Text(widget.variant.title)),
                      for (final currency in widget.currencies)
                        SizedBox(
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: TextFormField(
                              key: ValueKey('variant-price-$currency'),
                              controller: _prices[currency],
                              enabled: !busy,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                              ),
                              validator: (value) =>
                                  _validateAmount(value, currency),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _failure(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      );

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final request = AdminUpdateVariantPrices(prices: [
      for (final currency in widget.currencies)
        AdminUpdateVariantPrice(
          currencyCode: currency,
          amount: parseMinorUnits(_prices[currency]!.text, currency)!,
        ),
    ]);
    final saved = await context
        .readAdminProductDetailViewModel()
        .updateVariantPrices(widget.product.id, widget.variant.id, request);
    if (saved && mounted) Navigator.of(context).pop(true);
  }
}

String? _validateAmount(String? value, String currency) =>
    value == null || parseMinorUnits(value, currency) == null
        ? 'Enter a valid price'
        : null;
