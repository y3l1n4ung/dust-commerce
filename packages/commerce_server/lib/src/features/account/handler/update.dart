import 'package:commerce_server/src/features/account/deps.dart';
import 'package:commerce_server/src/features/account/extractor.dart';
import 'package:commerce_server/src/features/account/model.dart';
import 'package:commerce_server/src/features/account/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/server.dart';

const ValidatedExtractable<UpdateCustomerProfileBody> _profileBody =
    ValidatedExtractable(
  JsonExtractable<UpdateCustomerProfileBody>(
    UpdateCustomerProfileBody.fromJson,
  ),
);
const ValidatedExtractable<CustomerAddressInput> _addressBody =
    ValidatedExtractable(
  JsonExtractable<CustomerAddressInput>(CustomerAddressInput.fromJson),
);

/// `PATCH /store/customers/me` — replace editable public profile fields.
Future<Result<CustomerResponse, Rejection>> updateCustomerHandler(
  Request request,
) async {
  final actor = await request.extract(
    const Extension<AuthenticatedCustomer>(),
  );
  final decoded = await _profileBody.extract(request);
  if (decoded case Err(:final error)) return Err(error);
  final deps = await request.state<AccountDeps>();
  final result = await updateCustomerProfile(
    deps.updates,
    actor.customer.id,
    (decoded as Ok<UpdateCustomerProfileBody, Rejection>).value,
  );
  return switch (result) {
    Ok(value: Some(value: final customer)) => Ok(customer),
    Ok(value: None()) => const Err(Rejection.notFound('Customer')),
    Err() => const Err(Rejection.internal()),
  };
}

/// `PATCH /store/customers/me/addresses/{addressId}` — update an owned row.
Future<Result<CustomerAddressResponse, Rejection>> updateAddressHandler(
  Request request,
) async {
  final addressId = pathParametersOf(request)['addressId'];
  if (addressId == null || addressId.isEmpty) {
    return const Err(Rejection.badRequest('An address id is required'));
  }
  final actor = await request.extract(
    const Extension<AuthenticatedCustomer>(),
  );
  final decoded = await _addressBody.extract(request);
  if (decoded case Err(:final error)) return Err(error);
  final deps = await request.state<AccountDeps>();
  final result = await updateCustomerAddress(
    deps.updates,
    addressId,
    actor.customer.id,
    (decoded as Ok<CustomerAddressInput, Rejection>).value,
  );
  return switch (result) {
    Ok(value: Some(value: final address)) => Ok(address),
    Ok(value: None()) => const Err(Rejection.notFound('Address')),
    Err() => const Err(Rejection.internal()),
  };
}
