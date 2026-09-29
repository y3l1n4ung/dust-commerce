import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/fp.dart';

/// Source-shaped progress toward a conditional zero-cost delivery option.
final class FreeShippingProgress {
  /// Creates immutable display progress from server-owned amounts.
  const FreeShippingProgress({
    required this.remaining,
    required this.fraction,
    required this.targetReached,
  });

  /// Progress bar width, clamped to its visible track.
  final double fraction;

  /// Amount still needed to satisfy the minimum.
  final Money remaining;

  /// Whether the zero-cost option is already available.
  final bool targetReached;
}

/// Finds the first Medusa-shaped free-shipping minimum for [cart].
Option<FreeShippingProgress> freeShippingProgressOf(
  CartView cart,
  List<ShippingOption> options,
) {
  for (final option in options) {
    if (option.amount.amount != 0 ||
        option.amount.currencyCode != cart.subtotal.currencyCode) {
      continue;
    }
    for (final rule in option.priceRules) {
      if (rule.attribute != ShippingPriceRuleAttribute.itemTotal) continue;
      final target = switch (rule.operator) {
        ShippingPriceRuleOperator.gt => Some(rule.value + 1),
        ShippingPriceRuleOperator.gte => Some(rule.value),
        _ => const None<int>(),
      };
      if (target case Some<int>(value: final minimum)) {
        final current = cart.subtotal.amount;
        final reached = current >= minimum;
        final remaining = reached ? 0 : minimum - current;
        final fraction =
            minimum == 0 ? 1.0 : (current / minimum).clamp(0.0, 1.0);
        return Some(FreeShippingProgress(
          remaining: Money.of(remaining, cart.subtotal.currencyCode),
          fraction: fraction,
          targetReached: reached,
        ));
      }
    }
  }
  return const None<FreeShippingProgress>();
}
