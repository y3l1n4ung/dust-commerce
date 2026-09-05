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
INSERT INTO line_items (id, cart_id, variant_id, product_id, title,
                        variant_title, unit_amount, currency_code, quantity)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
''')
  Future<Result<ExecResult, SqlxError>> insertLine(
    String id,
    String cartId,
    String variantId,
    String productId,
    String title,
    String? variantTitle,
    int unitAmount,
    String currencyCode,
    int quantity,
  );

  /// Sets the quantity of an existing line, keeping its price snapshot.
  @Query(r'UPDATE line_items SET quantity = $2 WHERE id = $1')
  Future<Result<ExecResult, SqlxError>> setLineQuantity(
    String lineId,
    int quantity,
  );

  /// Removes a line.
  @Query(r'DELETE FROM line_items WHERE id = $1 AND cart_id = $2')
  Future<Result<ExecResult, SqlxError>> deleteLine(
    String lineId,
    String cartId,
  );

  /// Records the email a guest checkout collected.
  @Query(r'UPDATE carts SET email = $2 WHERE id = $1')
  Future<Result<ExecResult, SqlxError>> setCartEmail(
    String cartId,
    String email,
  );
}
