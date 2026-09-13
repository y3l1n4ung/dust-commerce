import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:commerce_server/src/features/admin/extractor.dart';
import 'package:commerce_server/src/features/admin_shipping_profile/deps.dart';
import 'package:commerce_server/src/features/admin_shipping_profile/model.dart';
import 'package:commerce_server/src/features/admin_shipping_profile/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

const ValidatedExtractable<AdminUpdateProductShippingProfile>
    _updateProductShippingProfileBody = ValidatedExtractable(
  JsonExtractable<AdminUpdateProductShippingProfile>(
    AdminUpdateProductShippingProfile.fromJson,
  ),
);

/// `GET /admin/shipping-profiles` — lists choices for a proven merchant.
Future<Result<AdminShippingProfileListResponse, Rejection>>
    listAdminShippingProfilesHandler(Request request) async {
  final actor = await const Extension<AuthenticatedAdmin>().extract(request);
  if (actor case Err(:final error)) return Err(error);
  final state = await adminShippingProfileDeps(request);
  if (state case Err(:final error)) return Err(error);
  final query = request.requestedUri.queryParameters;
  final limit = int.tryParse(query['limit'] ?? '') ?? defaultLimit;
  final offset = int.tryParse(query['offset'] ?? '') ?? 0;
  final deps = (state as Ok<AdminShippingProfileDeps, Rejection>).value;
  final result = await listAdminShippingProfiles(
    deps.profiles,
    query: query['q'] ?? '',
    limit: limit.clamp(1, 1000),
    offset: offset < 0 ? 0 : offset,
  );
  return switch (result) {
    Ok(:final value) => Ok(value),
    Err() => const Err(Rejection.internal()),
  };
}

/// `PATCH /admin/products/{id}/shipping-profile` — replaces fulfillment.
Future<Result<AdminProductShippingProfileResponse, Rejection>>
    updateAdminProductShippingProfileHandler(Request request) async {
  final actor = await const Extension<AuthenticatedAdmin>().extract(request);
  if (actor case Err(:final error)) return Err(error);
  final productId = pathParametersOf(request)['id'];
  if (productId == null || productId.isEmpty) {
    return const Err(Rejection.badRequest('A product id is required'));
  }
  final decoded = await _updateProductShippingProfileBody.extract(request);
  if (decoded case Err(:final error)) return Err(error);
  final state = await adminShippingProfileDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<AdminShippingProfileDeps, Rejection>).value;
  final result = await replaceAdminProductShippingProfile(
    deps.database,
    productId,
    (decoded as Ok<AdminUpdateProductShippingProfile, Rejection>).value,
    nextId: deps.clock.nextId,
  );
  return switch (result) {
    Ok(:final value) => Ok(value),
    Err(error: AdminProductShippingProfileUpdateFailure.notFound) =>
      Err(Rejection.notFound('Product "$productId"')),
    Err(error: AdminProductShippingProfileUpdateFailure.invalid) =>
      const Err(Rejection.status(422, 'Choose an active shipping profile')),
    Err(error: AdminProductShippingProfileUpdateFailure.internal) =>
      const Err(Rejection.internal()),
  };
}
