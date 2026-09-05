import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'model.g.dart';

/// Direct credential-query response used only for password verification.
///
/// It deliberately derives no serializer: a type containing a password hash
/// must never become an HTTP response by accident.
@Derive([Eq(), FromRow()])
final class PasswordCredential with _$PasswordCredential {
  /// Creates a credential query response.
  const PasswordCredential({
    required this.authIdentityId,
    required this.passwordHash,
  });

  /// Medusa-style authentication identity owning this provider credential.
  @Sqlx(rename: 'auth_identity_id')
  final String authIdentityId;

  /// Argon2id PHC string; never returned by an HTTP handler.
  @Sqlx(rename: 'password_hash')
  final String passwordHash;
}

/// Explicit customer response populated directly from a customer row.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class CustomerResponse with _$CustomerResponse {
  /// Constructs the allowlisted customer response.
  const CustomerResponse({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  /// Email used for account communication and sign-in.
  final String email;

  /// Optional given name from the customer profile.
  @Sqlx(rename: 'first_name')
  final String? firstName;

  /// Stable customer identifier.
  final String id;

  /// Optional family name from the customer profile.
  @Sqlx(rename: 'last_name')
  final String? lastName;

  /// Optional customer contact number.
  final String? phone;
}
