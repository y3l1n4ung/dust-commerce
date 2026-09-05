import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

part 'promotion.g.dart';

/// One row of `promotions`.
@Derive([ToString(), Eq(), FromRow()])
final class PromotionRow with _$PromotionRow {
  /// Creates a [PromotionRow].
  const PromotionRow({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.usageCount,
    this.currencyCode,
    this.startsAt,
    this.endsAt,
    this.usageLimit,
  });

  /// The code a customer types.
  final String code;

  /// The currency a fixed amount is in.
  @Sqlx(rename: 'currency_code')
  final String? currencyCode;

  /// When it stops working, ISO-8601.
  @Sqlx(rename: 'ends_at')
  final String? endsAt;

  /// The primary key.
  final String id;

  /// When it starts working, ISO-8601.
  @Sqlx(rename: 'starts_at')
  final String? startsAt;

  /// `percentage` or `fixed`, as stored.
  final String type;

  /// How many times it has been redeemed.
  @Sqlx(rename: 'usage_count')
  final int usageCount;

  /// How many redemptions are allowed.
  @Sqlx(rename: 'usage_limit')
  final int? usageLimit;

  /// Basis points, or minor units.
  final int value;
}

/// One row of `cart_promotions`: what a cart has applied.
@Derive([ToString(), Eq(), FromRow()])
final class CartPromotionRow with _$CartPromotionRow {
  /// Creates a [CartPromotionRow].
  const CartPromotionRow({
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

/// Builds the domain [Promotion] a row describes.
///
/// An unreadable type is treated as a percentage of nothing rather than
/// throwing: a row written by a future version should not take the shop down,
/// and a promotion that discounts nothing is the safe reading.
Promotion promotionOf(PromotionRow row) => Promotion(
      id: row.id,
      code: row.code,
      type:
          row.type == 'fixed' ? PromotionType.fixed : PromotionType.percentage,
      value: row.type == 'fixed' || row.type == 'percentage' ? row.value : 0,
      currencyCode: row.currencyCode,
      startsAt: row.startsAt == null ? null : DateTime.parse(row.startsAt!),
      endsAt: row.endsAt == null ? null : DateTime.parse(row.endsAt!),
      usageLimit: row.usageLimit,
      usageCount: row.usageCount,
    );
