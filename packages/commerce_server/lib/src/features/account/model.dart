import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

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

/// The body accepted when a customer creates an account.
@Derive([Deserialize(), Validate()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class RegisterAccountBody with _$RegisterAccountBody {
  /// Creates a registration body.
  const RegisterAccountBody({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.phone,
  });

  /// Decodes JSON using Dust.
  factory RegisterAccountBody.fromJson(Map<String, Object?> json) =>
      _$RegisterAccountBodyFromJson(_trimEmail(json));

  /// Customer email, normalized before persistence.
  @Validate(length: Length(min: 3, max: 254), message: 'Enter a valid email')
  @Validate(email: true, message: 'Enter a valid email')
  final String email;

  /// Optional customer first name.
  @Validate(
      length: Length(min: 1, max: 100), message: 'Use 1 to 100 characters')
  final String? firstName;

  /// Optional customer last name.
  @Validate(
      length: Length(min: 1, max: 100), message: 'Use 1 to 100 characters')
  final String? lastName;

  /// Plaintext password accepted only at this request boundary.
  @Validate(
    length: Length(min: 12, max: 1024),
    message: 'Use 12 to 1024 characters',
  )
  final String password;

  /// Optional customer phone number.
  @Validate(length: Length(max: 50), message: 'Use at most 50 characters')
  final String? phone;
}

/// The body accepted by email/password sign-in.
@Derive([Deserialize(), Validate()])
final class Credentials with _$Credentials {
  /// Creates credentials.
  const Credentials({required this.email, required this.password});

  /// Decodes JSON using Dust.
  factory Credentials.fromJson(Map<String, Object?> json) =>
      _$CredentialsFromJson(_trimEmail(json));

  /// Customer sign-in email.
  @Validate(length: Length(min: 3, max: 254), message: 'Enter a valid email')
  @Validate(email: true, message: 'Enter a valid email')
  final String email;

  /// Plaintext password accepted only at this request boundary.
  @Validate(
    length: Length(min: 12, max: 1024),
    message: 'Use 12 to 1024 characters',
  )
  final String password;
}

/// A newly issued bearer token, shown exactly once.
@Derive([Serialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class IssuedToken with _$IssuedToken {
  /// Creates a token response.
  const IssuedToken({required this.token, required this.expiresAt});

  /// Opaque bearer token returned once; only its fingerprint is stored.
  final String token;

  /// UTC ISO-8601 expiry instant.
  final String expiresAt;
}

Map<String, Object?> _trimEmail(Map<String, Object?> json) {
  final email = json['email'];
  return email is String ? {...json, 'email': email.trim()} : json;
}
