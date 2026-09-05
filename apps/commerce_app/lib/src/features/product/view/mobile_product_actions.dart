import 'package:commerce_app/commerce_app.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Fixed purchase controls translated from Medusa DTC MobileActions.
class MobileProductActions extends StatelessWidget {
  /// Creates the sticky mobile purchase surface.
  const MobileProductActions({required this.state, super.key});

  /// Product and selection currently visible on the route.
  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    final product = state.product!;
    final hasOptions = product.variants.length > 1;
    return Material(
      color: StoreColors.base,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: StoreColors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: TranslatedText(
                      'shop_price_separator',
                      defaultText: '—',
                    ),
                  ),
                  ProductPrice(state: state, compact: true),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (hasOptions) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showOptions(context),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _optionLabel(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(child: ProductPurchaseButton(state: state)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _optionLabel(BuildContext context) {
    final product = state.product!;
    final values = [
      for (final option in product.options) state.selection[option.id],
    ].whereType<String>().toList(growable: false);
    return values.length == product.options.length
        ? values.join(' / ')
        : context.tr('shop_select_options', defaultText: 'Select options');
  }

  Future<void> _showOptions(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        barrierColor: StoreColors.foregroundSubtle.withValues(alpha: 0.75),
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (_) => const _MobileOptionsSheet(),
      );
}

class _MobileOptionsSheet extends StatelessWidget {
  const _MobileOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watchProductViewModel().value;
    final busy =
        context.watchCartViewModel().value.status == CartStatus.loading;
    if (state.product == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 24),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Material(
                color: StoreColors.base,
                shape: const CircleBorder(),
                child: SizedBox.square(
                  dimension: 48,
                  child: IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ColoredBox(
            color: StoreColors.base,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
              child: ProductOptionGroups(state: state, disabled: busy),
            ),
          ),
        ],
      ),
    );
  }
}
