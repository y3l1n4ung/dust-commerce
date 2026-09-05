import 'dart:convert';

import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'shipping.g.dart';

/// Explicit shipping-method response populated directly by SQLx.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class ShippingMethodResponse with _$ShippingMethodResponse {
  /// Creates an allowlisted shipping method.
  const ShippingMethodResponse({
    required this.optionId,
    required this.name,
    required this.amount,
  });

  /// Delivery price snapshot.
  @Sqlx(tryFrom: ShippingMoneyFromJson())
  final Money amount;

  /// Delivery service display name.
  final String name;

  /// Stable shipping-option identifier.
  @Sqlx(rename: 'option_id')
  final String optionId;
}

/// Converts the shipping amount selected as a JSON object.
final class ShippingMoneyFromJson implements SqlxTryFrom<Money, String> {
  /// Creates the stateless converter.
  const ShippingMoneyFromJson();

  @override
  Money decode(String value) => Money.fromJson(
        jsonDecode(value) as Map<String, Object?>,
      );
}
