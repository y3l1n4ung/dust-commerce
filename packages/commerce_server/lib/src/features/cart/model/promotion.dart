import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

part 'promotion.g.dart';

/// Direct query response for the promotion currently applied to a cart.
@Derive([ToString(), Eq(), FromRow()])
final class AppliedPromotion with _$AppliedPromotion {
  /// Creates an [AppliedPromotion].
  const AppliedPromotion({
    required this.promotionId,
    required this.code,
    required this.amount,
  });

  /// What it took off, snapshotted when applied.
  final int amount;

  /// The code as typed.
  final String code;

  /// The promotion it came from.
  @Sqlx(rename: 'promotion_id')
  final String promotionId;
}

/// Internal promotion query result used directly by cart policy.
@Derive([FromRow()])
final class PromotionPolicy {
  /// Constructs the policy input directly from its query row.
  PromotionPolicy({
    required this.promotionId,
    required this.promotionCode,
    required this.storedType,
    required this.promotionValue,
    required this.promotionUsageCount,
    this.promotionCurrencyCode,
    this.startsAtText,
    this.endsAtText,
    this.promotionUsageLimit,
  });

  /// Stored exclusive validity end.
  @Sqlx(rename: 'ends_at')
  final String? endsAtText;

  /// Promotion code matched case-insensitively in SQL.
  @Sqlx(rename: 'code')
  final String promotionCode;

  /// Currency required by fixed promotions.
  @Sqlx(rename: 'currency_code')
  final String? promotionCurrencyCode;

  /// Stable promotion identifier.
  @Sqlx(rename: 'id')
  final String promotionId;

  /// Number of redemptions recorded so far.
  @Sqlx(rename: 'usage_count')
  final int promotionUsageCount;

  /// Maximum redemptions, when the merchant set one.
  @Sqlx(rename: 'usage_limit')
  final int? promotionUsageLimit;

  /// Percentage basis points or fixed minor-unit amount.
  @Sqlx(rename: 'value')
  final int promotionValue;

  /// Stored inclusive validity start.
  @Sqlx(rename: 'starts_at')
  final String? startsAtText;

  /// Stored promotion type name.
  @Sqlx(rename: 'type')
  final String storedType;

  /// Customer-entered promotion code.
  String get code => promotionCode;

  /// Currency required by a fixed promotion.
  String? get currencyCode => promotionCurrencyCode;

  /// Stable promotion identifier.
  String get id => promotionId;

  /// Decoded promotion strategy.
  PromotionType get type =>
      storedType == 'fixed' ? PromotionType.fixed : PromotionType.percentage;

  /// Computes the discount without constructing a second promotion model.
  Money discountOn(Money subtotal) {
    final amount = type == PromotionType.fixed
        ? promotionValue
        : (subtotal.amount * promotionValue + 5000) ~/ 10000;
    final discount = Money(
      amount: amount,
      currencyCode: promotionCurrencyCode ?? subtotal.currencyCode,
    );
    return discount > subtotal ? subtotal : discount;
  }

  /// Whether the promotion is within its configured window and usage limit.
  bool isUsableAt(DateTime when) {
    final starts = startsAtText == null ? null : DateTime.parse(startsAtText!);
    final ends = endsAtText == null ? null : DateTime.parse(endsAtText!);
    if (starts != null && when.isBefore(starts)) return false;
    if (ends != null && !when.isBefore(ends)) return false;
    final limit = promotionUsageLimit;
    return limit == null || promotionUsageCount < limit;
  }
}
