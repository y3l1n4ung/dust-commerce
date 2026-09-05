import 'package:dust_dart/serde.dart';

part 'customer.g.dart';

/// Someone who has bought, or is about to.
///
/// A customer is optional at checkout. A guest orders with an email alone,
/// and the account is created later if they want one, so nothing here is
/// required to place an order.
@Derive([ToString(), Eq(), CopyWith(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class Customer with _$Customer {
  /// Creates a [Customer].
  const Customer({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  /// Creates a [Customer] from JSON.
  factory Customer.fromJson(Map<String, Object?> json) =>
      _$CustomerFromJson(json);

  /// Contact address, and the identity a guest order is matched on.
  final String email;

  /// Given name.
  final String? firstName;

  /// Unique identifier.
  final String id;

  /// Family name.
  final String? lastName;

  /// Contact number.
  final String? phone;

  /// The display name, falling back to the email when no name is known.
  String get displayName {
    final parts = [firstName, lastName].whereType<String>();
    return parts.isEmpty ? email : parts.join(' ');
  }
}
