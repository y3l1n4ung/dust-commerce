import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/admin/model.dart';
import 'package:commerce_server/src/features/admin/repository/repository.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:commerce_server/src/infra/option.dart';
import 'package:dust_dart/db.dart';

/// Business reason an option replacement could not be committed.
enum AdminUpdateProductOptionFailure {
  /// The title or values are empty, too long, or duplicated.
  invalid,

  /// No active product owns the requested active option.
  notFound,

  /// Another option on the product already uses the requested title.
  titleConflict,

  /// A live variant still selects a value the request removes.
  valueInUse,
}

/// Atomically replaces one option's title, values, and display order.
Future<
    Result<Result<AdminProductDetailResponse, AdminUpdateProductOptionFailure>,
        SqlxError>> updateAdminProductOption(
  CommerceDatabase database,
  String productId,
  String optionId,
  AdminUpdateProductOption input, {
  required String Function() nextId,
}) async {
  final title = input.title.trim();
  final values = input.values.map((value) => value.trim()).toList();
  if (!_valid(title, values)) {
    return const Ok(Err(AdminUpdateProductOptionFailure.invalid));
  }
  return database.transaction((tx) async {
    final reads = AdminProductReadRepository(tx);
    final found = await reads.findById(productId);
    if (found case Err(:final error)) return Err(error);
    final product = optionOf(
      (found as Ok<AdminProductDetailResponse?, SqlxError>).value,
    );
    if (product case None()) {
      return const Ok(Err(AdminUpdateProductOptionFailure.notFound));
    }
    final detail = (product as Some<AdminProductDetailResponse>).value;
    final option = _option(detail.options, optionId);
    if (option case None()) {
      return const Ok(Err(AdminUpdateProductOptionFailure.notFound));
    }
    final current = (option as Some<AdminProductOption>).value;
    final writes = AdminProductOptionUpdateRepository(tx);

    for (final value
        in current.values.where((value) => !values.contains(value))) {
      final count = await writes.selectionCount(optionId, value);
      if (count case Err(:final error)) return Err(error);
      if ((count as Ok<int, SqlxError>).value > 0) {
        return const Ok(Err(AdminUpdateProductOptionFailure.valueInUse));
      }
    }
    final renamed = await writes.updateTitle(productId, optionId, title);
    if (renamed case Err(:final error)) return Err(error);
    if ((renamed as Ok<ExecResult, SqlxError>).value.rowsAffected == 0) {
      return const Ok(Err(AdminUpdateProductOptionFailure.titleConflict));
    }
    for (var rank = 0; rank < values.length; rank++) {
      final value = values[rank];
      final write = current.values.contains(value)
          ? await writes.rankValue(optionId, value, rank)
          : await writes.insertValue(nextId(), optionId, value, rank);
      if (write case Err(:final error)) return Err(error);
    }
    for (final value
        in current.values.where((value) => !values.contains(value))) {
      final removed = await writes.deleteValue(optionId, value);
      if (removed case Err(:final error)) return Err(error);
      if ((removed as Ok<ExecResult, SqlxError>).value.rowsAffected == 0) {
        return const Ok(Err(AdminUpdateProductOptionFailure.valueInUse));
      }
    }
    return _readBack(reads, productId);
  });
}

Option<AdminProductOption> _option(
  List<AdminProductOption> options,
  String id,
) {
  for (final option in options) {
    if (option.id == id) return Some(option);
  }
  return const None();
}

Future<
    Result<Result<AdminProductDetailResponse, AdminUpdateProductOptionFailure>,
        SqlxError>> _readBack(
  AdminProductReadRepository reads,
  String productId,
) async {
  final refreshed = await reads.findById(productId);
  if (refreshed case Err(:final error)) return Err(error);
  return switch (optionOf(
    (refreshed as Ok<AdminProductDetailResponse?, SqlxError>).value,
  )) {
    Some(:final value) => Ok(Ok(value)),
    None() => const Ok(Err(AdminUpdateProductOptionFailure.notFound)),
  };
}

bool _valid(String title, List<String> values) =>
    title.isNotEmpty &&
    title.length <= 255 &&
    values.isNotEmpty &&
    values.every((value) => value.isNotEmpty && value.length <= 255) &&
    values.toSet().length == values.length;
