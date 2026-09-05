import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:dust_dart/db.dart';

/// Removes [lineId] only when it belongs to [cartId].
///
/// Returns `Ok(false)` when the scoped line does not exist.
Future<Result<bool, SqlxError>> removeLine(
  CartUpdateRepository writes, {
  required String cartId,
  required String lineId,
}) async {
  final deleted = await writes.deleteLine(lineId, cartId);
  if (deleted case Err(:final error)) return Err(error);
  return Ok((deleted as Ok<ExecResult, SqlxError>).value.rowsAffected > 0);
}
