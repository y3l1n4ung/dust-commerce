import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'free_shipping_progress_summary.dart';

/// Global popup translated from Medusa's `FreeShippingPriceNudge`.
final class FreeShippingPriceNudge extends StatelessWidget {
  /// Creates the source-shaped free-shipping popup.
  const FreeShippingPriceNudge({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watchCartViewModel().value;
    final cart = state.cart;
    if (cart == null || state.isFreeShippingNudgeDismissedFor(cart.cart.id)) {
      return const SizedBox.shrink();
    }
    final progress = freeShippingProgressOf(cart, state.shippingOptions);
    return switch (progress) {
      Some<FreeShippingProgress>(:final value) when !value.targetReached =>
        _popup(context, value),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _popup(BuildContext context, FreeShippingProgress progress) =>
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: context.readCartViewModel().dismissFreeShippingNudge,
              tooltip: context.tr(
                'shop_free_shipping_close',
                defaultText: 'Close free shipping message',
              ),
              style: IconButton.styleFrom(
                backgroundColor: StoreColors.foreground,
                foregroundColor: StoreColors.base,
              ),
              icon: const Icon(Icons.close, size: 20),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FreeShippingProgressSummary(progress: progress),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => context.navigator.cart().go(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: StoreColors.base,
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: StoreColors.base),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const TranslatedText(
                            'shop_free_shipping_view_cart',
                            defaultText: 'View cart',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.navigator.store().go(),
                            style: FilledButton.styleFrom(
                              backgroundColor: StoreColors.base,
                              foregroundColor: StoreColors.foreground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const TranslatedText(
                              'shop_free_shipping_view_products',
                              defaultText: 'View products',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
