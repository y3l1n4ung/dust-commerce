import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

part 'model.g.dart';

/// A customer account joined to its email/password provider identity.
///
/// It deliberately derives no serializer: a type containing a password hash
/// must never become an HTTP response by accident.
@Derive([Eq(), FromRow()])
final class AccountRow with _$AccountRow {
  /// Creates a row mapped by Dust SQLx.
  const AccountRow({
    required this.authIdentityId,
    required this.customerId,
    required this.email,
    required this.passwordHash,
    this.firstName,
    this.lastName,
    this.phone,
  });

  /// Medusa-style authentication identity owning this provider credential.
  @Sqlx(rename: 'auth_identity_id')
  final String authIdentityId;

  /// Store customer linked through the identity metadata.
  @Sqlx(rename: 'customer_id')
  final String customerId;

  /// Normalized sign-in email.
  final String email;

  /// Optional customer first name.
  @Sqlx(rename: 'first_name')
  final String? firstName;

  /// Optional customer last name.
  @Sqlx(rename: 'last_name')
  final String? lastName;

  /// Argon2id PHC string; never returned by an HTTP handler.
  @Sqlx(rename: 'password_hash')
  final String passwordHash;

  /// Optional customer phone number.
  final String? phone;

  /// The safe public projection.
  Customer get customer => Customer(
        id: customerId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
}

/// A customer resolved from a valid, unexpired bearer token.
@Derive([Eq(), FromRow()])
final class AuthenticatedCustomerRow with _$AuthenticatedCustomerRow {
  /// Creates a row mapped by Dust SQLx.
  const AuthenticatedCustomerRow({
    required this.authIdentityId,
    required this.customerId,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  /// Authentication identity proven by the bearer token.
  @Sqlx(rename: 'auth_identity_id')
  final String authIdentityId;

  /// Customer linked to the authenticated identity.
  @Sqlx(rename: 'customer_id')
  final String customerId;

  /// Normalized customer email.
  final String email;

  /// Optional customer first name.
  @Sqlx(rename: 'first_name')
  final String? firstName;

  /// Optional customer last name.
  @Sqlx(rename: 'last_name')
  final String? lastName;

  /// Optional customer phone number.
  final String? phone;

  /// The safe public projection.
  Customer get customer => Customer(
        id: customerId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
}
