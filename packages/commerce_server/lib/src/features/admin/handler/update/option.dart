import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/admin/deps.dart';
import 'package:commerce_server/src/features/admin/model.dart';
import 'package:commerce_server/src/features/admin/service/service.dart';
import 'package:dust_server/server.dart';

const ValidatedExtractable<AdminUpdateProductOption> _body =
    ValidatedExtractable(
  JsonExtractable<AdminUpdateProductOption>(AdminUpdateProductOption.fromJson),
);

/// `PATCH /admin/products/{id}/options/{option_id}` — edit one option.
Future<Result<AdminProductDetailResponse, Rejection>>
    updateAdminProductOptionHandler(Request request) async {
  final parameters = pathParametersOf(request);
  final productId = parameters['id'];
  final optionId = parameters['option_id'];
  if (productId == null ||
      productId.isEmpty ||
      optionId == null ||
      optionId.isEmpty) {
    return const Err(
      Rejection.badRequest('Product and option ids are required'),
    );
  }
  final decoded = await _body.extract(request);
  if (decoded case Err(:final error)) return Err(error);
  final state = await adminDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<AdminDeps, Rejection>).value;
  final result = await updateAdminProductOption(
    deps.database,
    productId,
    optionId,
    (decoded as Ok<AdminUpdateProductOption, Rejection>).value,
    nextId: deps.clock.nextId,
  );
  return switch (result) {
    Ok(value: Ok(value: final product)) => Ok(product),
    Ok(value: Err(error: AdminUpdateProductOptionFailure.notFound)) =>
      Err(Rejection.notFound('Product option "$optionId"')),
    Ok(value: Err(error: AdminUpdateProductOptionFailure.invalid)) =>
      const Err(Rejection.status(422, 'Add at least one unique option value')),
    Ok(value: Err(error: AdminUpdateProductOptionFailure.titleConflict)) =>
      const Err(Rejection.conflict('Another option already uses this title')),
    Ok(value: Err(error: AdminUpdateProductOptionFailure.valueInUse)) =>
      const Err(Rejection.conflict(
        'A product variant still uses one of the removed values',
      )),
    Err() => const Err(Rejection.internal()),
  };
}
