import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'region.g.dart';

/// Explicit selling-region response.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class RegionResponse with _$RegionResponse {
  /// Creates an allowlisted selling region.
  const RegionResponse({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.taxRate,
    required this.countries,
    required this.taxInclusive,
  });

  /// ISO country codes served by this region.
  @Sqlx(tryFrom: CountriesFromCsv())
  final List<String> countries;

  /// Currency used by every regional amount.
  @Sqlx(rename: 'currency_code')
  final String currencyCode;

  /// Stable region identifier.
  final String id;

  /// Customer-facing region name.
  final String name;

  /// Whether displayed amounts already contain tax.
  @Sqlx(rename: 'tax_inclusive', tryFrom: BoolFromInt())
  final bool taxInclusive;

  /// Tax rate in basis points.
  @Sqlx(rename: 'tax_rate')
  final int taxRate;
}

/// Converts SQLite's integer boolean representation.
final class BoolFromInt implements SqlxTryFrom<bool, int> {
  /// Creates the stateless converter.
  const BoolFromInt();

  @override
  bool decode(int value) => value != 0;
}

/// Converts the compact region country list.
final class CountriesFromCsv implements SqlxTryFrom<List<String>, String> {
  /// Creates the stateless converter.
  const CountriesFromCsv();

  @override
  List<String> decode(String value) => value
      .split(',')
      .where((country) => country.isNotEmpty)
      .toList(growable: false);
}
