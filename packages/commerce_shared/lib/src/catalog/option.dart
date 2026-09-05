import 'package:dust_dart/serde.dart';

part 'option.g.dart';

/// An axis a product varies along: Size, Colour, Material.
///
/// The option holds the permitted values; a variant picks one value per
/// option. Keeping the axis on the product rather than on each variant is
/// what lets a storefront render a size selector without inspecting every
/// variant to discover the sizes.
@Derive([ToString(), Eq(), CopyWith(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
class ProductOption with _$ProductOption {
  /// Creates a [ProductOption] from already-validated values.
  const ProductOption({
    required this.id,
    required this.title,
    required this.values,
  });

  /// Creates a [ProductOption], rejecting an empty or duplicated value set.
  factory ProductOption.of({
    required String id,
    required String title,
    required List<String> values,
  }) {
    if (values.isEmpty) {
      throw ArgumentError.value(
        values,
        'values',
        'an option with no values cannot be chosen',
      );
    }
    if (values.toSet().length != values.length) {
      throw ArgumentError.value(values, 'values', 'duplicate option value');
    }
    return ProductOption(id: id, title: title, values: values);
  }

  /// Creates a [ProductOption] from JSON.
  factory ProductOption.fromJson(Map<String, Object?> json) =>
      _$ProductOptionFromJson(json);

  /// Unique identifier.
  final String id;

  /// Display name, such as `Size`.
  final String title;

  /// The values a variant may choose from.
  final List<String> values;

  /// Whether [value] is one this option offers.
  bool offers(String value) => values.contains(value);
}
