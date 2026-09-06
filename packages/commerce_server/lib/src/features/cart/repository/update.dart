import 'package:dust_dart/db.dart';

part 'update.g.dart';

/// The writes that change what a cart holds.
@SqlxDao()
abstract final class CartUpdateRepository {
  /// Binds the queries to [db].
  const factory CartUpdateRepository(DatabaseExecutor db) =
      _$CartUpdateRepository;

  /// Adds a line, with the price snapshot taken by the caller.
  @Query(r'''
INSERT INTO line_items (id, cart_id, variant_id, product_id, product_handle,
                        thumbnail, title, variant_title, unit_amount,
                        currency_code, quantity)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
''')
  Future<Result<ExecResult, SqlxError>> insertLine(
    String id,
    String cartId,
    String variantId,
    String productId,
    String productHandle,
    String? thumbnail,
    String title,
    String? variantTitle,
    int unitAmount,
    String currencyCode,
    int quantity,
  );

  /// Sets the quantity of an existing line, keeping its price snapshot.
  @Query(
    r'UPDATE line_items SET quantity = $2 WHERE id = $1 AND cart_id = $3',
  )
  Future<Result<ExecResult, SqlxError>> setLineQuantity(
    String lineId,
    int quantity,
    String cartId,
  );

  /// Removes a line.
  @Query(r'DELETE FROM line_items WHERE id = $1 AND cart_id = $2')
  Future<Result<ExecResult, SqlxError>> deleteLine(
    String lineId,
    String cartId,
  );

  /// Applies a promotion, replacing any earlier one.
  ///
  /// One promotion per cart, so this is an upsert on the cart id. Stacking is
  /// a decision with rules of its own — which combine, which exclude — and a
  /// schema that allowed two without those rules would be a bug waiting.
  @Query(r'''
INSERT INTO cart_promotions (cart_id, promotion_id, code, amount)
VALUES ($1, $2, $3, $4)
ON CONFLICT (cart_id) DO UPDATE
SET promotion_id = excluded.promotion_id,
    code = excluded.code,
    amount = excluded.amount
''')
  Future<Result<ExecResult, SqlxError>> setPromotion(
    String cartId,
    String promotionId,
    String code,
    int amount,
  );

  /// Removes whatever promotion the cart had.
  @Query(r'DELETE FROM cart_promotions WHERE cart_id = $1')
  Future<Result<ExecResult, SqlxError>> clearPromotion(String cartId);

  /// Records the email a guest checkout collected.
  @Query(r'UPDATE carts SET email = $2 WHERE id = $1')
  Future<Result<ExecResult, SqlxError>> setCartEmail(
    String cartId,
    String email,
  );

  /// Claims an active guest cart for one authenticated customer.
  ///
  /// Matching the same customer makes retries safe after a response is lost.
  /// A cart owned by somebody else, completed, or deleted matches no rows.
  @Query(r'''
UPDATE carts
SET customer_id = $2, email = $3
WHERE id = $1
  AND (customer_id IS NULL OR customer_id = $2)
  AND completed_at IS NULL
  AND deleted_at IS NULL
''')
  Future<Result<ExecResult, SqlxError>> claimCart(
    String cartId,
    String customerId,
    String email,
  );
}

/// Atomic writes that keep a cart's chosen delivery method eligible.
@SqlxDao()
abstract final class CartShippingRepository {
  /// Binds shipping writes to [db].
  const factory CartShippingRepository(DatabaseExecutor db) =
      _$CartShippingRepository;

  /// Chooses a delivery method only while every rule matches the current cart.
  @Query(r'''
WITH cart_value(item_total) AS (
  SELECT coalesce(sum(line.unit_amount * line.quantity), 0)
  FROM line_items line
  WHERE line.cart_id = $1
)
INSERT INTO cart_shipping_methods (cart_id, option_id, name, amount)
SELECT $1, $2, $3, $4
FROM cart_value
WHERE NOT EXISTS (
  SELECT 1
  FROM shipping_option_price_rules rule
  WHERE rule.shipping_option_id = $2
    AND rule.deleted_at IS NULL
    AND NOT CASE rule.operator
      WHEN 'gt' THEN cart_value.item_total > rule.value
      WHEN 'gte' THEN cart_value.item_total >= rule.value
      WHEN 'lt' THEN cart_value.item_total < rule.value
      WHEN 'lte' THEN cart_value.item_total <= rule.value
      WHEN 'eq' THEN cart_value.item_total = rule.value
      ELSE 0
    END
)
ON CONFLICT (cart_id) DO UPDATE
SET option_id = excluded.option_id,
    name = excluded.name,
    amount = excluded.amount
''')
  Future<Result<ExecResult, SqlxError>> setShippingMethod(
    String cartId,
    String optionId,
    String name,
    int amount,
  );

  /// Clears a chosen option when a line mutation stops satisfying its rules.
  @Query(r'''
WITH cart_value(item_total) AS (
  SELECT coalesce(sum(line.unit_amount * line.quantity), 0)
  FROM line_items line
  WHERE line.cart_id = $1
)
DELETE FROM cart_shipping_methods AS method
WHERE method.cart_id = $1
  AND EXISTS (
    SELECT 1
    FROM shipping_option_price_rules rule, cart_value
    WHERE rule.shipping_option_id = method.option_id
      AND rule.deleted_at IS NULL
      AND NOT CASE rule.operator
        WHEN 'gt' THEN cart_value.item_total > rule.value
        WHEN 'gte' THEN cart_value.item_total >= rule.value
        WHEN 'lt' THEN cart_value.item_total < rule.value
        WHEN 'lte' THEN cart_value.item_total <= rule.value
        WHEN 'eq' THEN cart_value.item_total = rule.value
        ELSE 0
      END
  )
''')
  Future<Result<ExecResult, SqlxError>> clearIneligibleMethod(String cartId);
}
