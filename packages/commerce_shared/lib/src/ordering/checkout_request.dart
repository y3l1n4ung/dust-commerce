import 'package:commerce_shared/src/customers/address.dart';
import 'package:dust_dart/serde.dart';

part 'checkout_request.g.dart';

/// A postal address as it arrives from a form, before it is trusted.
///
/// Separate from [Address] on purpose. [Address] is a value the domain has
/// already accepted; this is whatever the client sent, including the empty
/// strings and typos a form produces. The two converge at [toAddress].
@Derive([ToString(), Eq(), CopyWith(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class AddressInput with _$AddressInput {
  /// Creates an [AddressInput].
  const AddressInput({
    required this.firstName,
    required this.lastName,
    required this.line1,
    required this.city,
    required this.postalCode,
    required this.countryCode,
    this.line2,
    this.province,
    this.phone,
  });

  /// Creates an [AddressInput] from JSON.
  factory AddressInput.fromJson(Map<String, Object?> json) =>
      _$AddressInputFromJson(json);

  /// Town or city.
  @Validate(length: Length(min: 1), message: 'Enter a city')
  final String city;

  /// ISO 3166-1 alpha-2 country code.
  @Validate(
    length: Length(min: 2, max: 2),
    message: 'Enter a two-letter country code',
  )
  final String countryCode;

  /// Given name.
  @Validate(length: Length(min: 1), message: 'Enter a first name')
  final String firstName;

  /// Family name.
  @Validate(length: Length(min: 1), message: 'Enter a last name')
  final String lastName;

  /// Street address.
  @Validate(length: Length(min: 1), message: 'Enter a street address')
  final String line1;

  /// Apartment, suite, or similar.
  final String? line2;

  /// Contact number for the courier.
  final String? phone;

  /// Postal or ZIP code.
  @Validate(length: Length(min: 1), message: 'Enter a postal code')
  final String postalCode;

  /// State, province, or region.
  final String? province;

  /// This input as a domain [Address].
  ///
  /// Call [validate] first. This still rejects a malformed country code,
  /// because [Address] will not hold one either.
  Address toAddress() => Address.of(
        firstName: firstName,
        lastName: lastName,
        line1: line1,
        line2: line2,
        city: city,
        province: province,
        postalCode: postalCode,
        countryCode: countryCode,
        phone: phone,
      );
}

/// The request that turns a cart into an order.
@Derive([ToString(), Eq(), CopyWith(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class CheckoutRequest with _$CheckoutRequest {
  /// Creates a [CheckoutRequest].
  const CheckoutRequest({
    required this.cartId,
    required this.email,
    required this.shippingAddress,
    this.billingAddress,
  });

  /// Creates a [CheckoutRequest] from JSON.
  factory CheckoutRequest.fromJson(Map<String, Object?> json) =>
      _$CheckoutRequestFromJson(json);

  /// Where the invoice goes, when it differs from the shipping address.
  @Validate(nested: true)
  final AddressInput? billingAddress;

  /// The cart being placed.
  @Validate(length: Length(min: 1), message: 'A checkout needs a cart')
  final String cartId;

  /// Where to send the receipt, and how a guest order is identified later.
  @Validate(length: Length(min: 1), message: 'Enter an email address')
  @Validate(email: true, message: 'Enter a valid email address')
  final String email;

  /// Where the goods go.
  @Validate(nested: true)
  final AddressInput shippingAddress;
}
