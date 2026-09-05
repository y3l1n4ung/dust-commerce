import 'package:commerce_server/src/features/account/model.dart';
import 'package:commerce_server/src/features/account/repository/repository.dart';
import 'package:commerce_server/src/infra/option.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Replaces the editable profile fields of one authenticated customer.
Future<Result<Option<CustomerResponse>, SqlxError>> updateCustomerProfile(
  AccountUpdateRepository updates,
  String customerId,
  UpdateCustomerProfileBody input,
) async {
  final result = await updates.updateProfile(
    customerId,
    input.firstName,
    input.lastName,
    input.phone,
  );
  return switch (result) {
    Ok(:final value) => Ok(optionOf(value)),
    Err(:final error) => Err(error),
  };
}

/// Replaces one address only when it belongs to the authenticated customer.
Future<Result<Option<CustomerAddressResponse>, SqlxError>>
    updateCustomerAddress(
  AccountUpdateRepository updates,
  String id,
  String customerId,
  CustomerAddressInput input,
) async {
  final result = await updates.updateAddress(
    id,
    customerId,
    input.firstName,
    input.lastName,
    input.company,
    input.phone,
    input.line1,
    input.line2,
    input.city,
    input.province,
    input.postalCode,
    input.countryCode,
    input.isDefaultShipping ? 1 : 0,
    input.isDefaultBilling ? 1 : 0,
  );
  return switch (result) {
    Ok(:final value) => Ok(optionOf(value)),
    Err(:final error) => Err(error),
  };
}
