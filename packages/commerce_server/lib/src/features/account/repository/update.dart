import 'package:commerce_server/src/features/account/model.dart';
import 'package:dust_dart/db.dart';

part 'update.g.dart';

/// Customer profile and owned-address mutations.
@SqlxDao()
abstract final class AccountUpdateRepository {
  /// Binds the queries to [db].
  const factory AccountUpdateRepository(DatabaseExecutor db) =
      _$AccountUpdateRepository;

  /// Replaces editable profile fields for one active customer.
  @Query(r'''
UPDATE customers
SET first_name = $2, last_name = $3, phone = $4
WHERE id = $1 AND has_account = 1 AND deleted_at IS NULL
RETURNING id, coalesce(email, '') AS email, first_name, last_name, phone
''')
  Future<Result<CustomerResponse?, SqlxError>> updateProfile(
    String customerId,
    String firstName,
    String lastName,
    String? phone,
  );

  /// Replaces one active address only when the customer owns it.
  @Query(r'''
UPDATE customer_addresses
SET first_name = $3, last_name = $4, company = $5, phone = $6,
    address_1 = $7, address_2 = $8, city = $9, province = $10,
    postal_code = $11, country_code = $12,
    is_default_shipping = $13, is_default_billing = $14
WHERE id = $1 AND customer_id = $2 AND deleted_at IS NULL
RETURNING id, first_name, last_name, company, phone, address_1, address_2,
          city, province, postal_code, country_code,
          is_default_shipping, is_default_billing
''')
  Future<Result<CustomerAddressResponse?, SqlxError>> updateAddress(
    String id,
    String customerId,
    String firstName,
    String lastName,
    String? company,
    String? phone,
    String line1,
    String? line2,
    String city,
    String? province,
    String postalCode,
    String countryCode,
    int isDefaultShipping,
    int isDefaultBilling,
  );
}
