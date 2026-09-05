import 'package:dust_dart/serde.dart';

part 'cart_request.g.dart';

/// The body of `POST /carts`.
///
/// Request contracts live beside the response contracts, in the shared
/// package, for the same reason: the client encodes this class and the server
/// decodes it, so the shape is declared once and a change breaks both ends at
/// compile time.
///
/// Every field is optional: a storefront that has not asked the customer where
/// they are still needs a cart.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class CreateCartBody with _$CreateCartBody {
  /// Creates a [CreateCartBody].
  const CreateCartBody({this.regionId, this.email});

  /// Creates a [CreateCartBody] from JSON.
  factory CreateCartBody.fromJson(Map<String, Object?> json) =>
      _$CreateCartBodyFromJson(json);

  /// Where to reach a guest, when it is known this early.
  @Validate(email: true, message: 'Enter a valid email address')
  final String? email;

  /// The region to sell in, when the storefront has chosen one.
  final String? regionId;
}

/// The body of `POST /carts/{id}/line-items`.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class AddLineBody with _$AddLineBody {
  /// Creates an [AddLineBody].
  const AddLineBody({required this.variantId, this.quantity = 1});

  /// Creates an [AddLineBody] from JSON.
  factory AddLineBody.fromJson(Map<String, Object?> json) =>
      _$AddLineBodyFromJson(json);

  /// How many to add.
  ///
  /// Absent means one. The Dart default is not enough on its own: the
  /// generated deserialiser requires every non-nullable key unless a
  /// `defaultValue` says what a missing one means.
  @SerDe(defaultValue: 1)
  @Validate(range: Range(min: 1), message: 'Order at least one')
  final int quantity;

  /// The variant being added.
  @Validate(length: Length(min: 1), message: 'variant_id is required')
  final String variantId;
}

/// The body of `POST /carts/{id}/shipping-method`.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class ChooseShippingBody with _$ChooseShippingBody {
  /// Creates a [ChooseShippingBody].
  const ChooseShippingBody({required this.optionId});

  /// Creates a [ChooseShippingBody] from JSON.
  factory ChooseShippingBody.fromJson(Map<String, Object?> json) =>
      _$ChooseShippingBodyFromJson(json);

  /// The option being chosen.
  @Validate(length: Length(min: 1), message: 'option_id is required')
  final String optionId;
}

/// The body of `POST /carts/{id}/promotions`.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class ApplyPromotionBody with _$ApplyPromotionBody {
  /// Creates an [ApplyPromotionBody].
  const ApplyPromotionBody({required this.code});

  /// Creates an [ApplyPromotionBody] from JSON.
  factory ApplyPromotionBody.fromJson(Map<String, Object?> json) =>
      _$ApplyPromotionBodyFromJson(json);

  /// The code a customer typed.
  @Validate(length: Length(min: 1), message: 'code is required')
  final String code;
}
