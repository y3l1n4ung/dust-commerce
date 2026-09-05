import 'package:dust_dart/serde.dart';

part 'money.g.dart';

/// An amount of money in the minor unit of a currency.
///
/// The amount is always an integer: 1999 in `usd` is $19.99. Money is never
/// held in a floating point type, because a binary fraction cannot represent
/// a decimal one and the error compounds across a cart.
///
/// Arithmetic and comparison are defined only within one currency. Mixing
/// currencies throws rather than converting, since a conversion needs a rate
/// and a rate needs a date.
@Derive([ToString(), Eq(), CopyWith(), Serialize(), Deserialize()])
class Money with _$Money {
  /// Creates a [Money] from an already-normalised [amount] and [currencyCode].
  ///
  /// Prefer [Money.of], which validates the currency code. This constructor
  /// stays unchecked so it can be `const` and so the generated deserialiser
  /// and `copyWith` can reach it.
  const Money({required this.amount, required this.currencyCode});

  /// Creates a [Money] of [amount] minor units in [currencyCode].
  ///
  /// The code is normalised to lower case, matching the ISO 4217 alpha-3
  /// convention this project stores everywhere. Throws [ArgumentError] when
  /// the code is not three letters.
  factory Money.of(int amount, String currencyCode) =>
      Money(amount: amount, currencyCode: _normalise(currencyCode));

  /// Creates a [Money] from JSON.
  factory Money.fromJson(Map<String, Object?> json) => _$MoneyFromJson(json);

  /// Creates a zero amount in [currencyCode].
  factory Money.zero(String currencyCode) => Money.of(0, currencyCode);

  /// The amount, in the minor unit of [currencyCode].
  final int amount;

  /// The ISO 4217 alpha-3 currency code, lower case.
  final String currencyCode;

  /// Whether this amount is zero.
  bool get isZero => amount == 0;

  /// Whether this amount is below zero.
  bool get isNegative => amount < 0;

  /// Adds [other], which must be in the same currency.
  Money operator +(Money other) =>
      Money(amount: amount + _matched(other), currencyCode: currencyCode);

  /// Subtracts [other], which must be in the same currency.
  Money operator -(Money other) =>
      Money(amount: amount - _matched(other), currencyCode: currencyCode);

  /// Multiplies this amount by [quantity].
  Money operator *(int quantity) =>
      Money(amount: amount * quantity, currencyCode: currencyCode);

  /// Whether this amount is below [other], which must be in the same currency.
  bool operator <(Money other) => amount < _matched(other);

  /// Whether this amount is at most [other], in the same currency.
  bool operator <=(Money other) => amount <= _matched(other);

  /// Whether this amount is above [other], in the same currency.
  bool operator >(Money other) => amount > _matched(other);

  /// Whether this amount is at least [other], in the same currency.
  bool operator >=(Money other) => amount >= _matched(other);

  /// Returns the amount of [other], or throws when its currency differs.
  int _matched(Money other) {
    if (other.currencyCode != currencyCode) {
      throw ArgumentError.value(
        other.currencyCode,
        'other',
        'currency mismatch: expected $currencyCode',
      );
    }
    return other.amount;
  }

  static final RegExp _alpha3 = RegExp(r'^[A-Za-z]{3}$');

  static String _normalise(String currencyCode) {
    if (!_alpha3.hasMatch(currencyCode)) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'expected a three-letter ISO 4217 code',
      );
    }
    return currencyCode.toLowerCase();
  }
}
