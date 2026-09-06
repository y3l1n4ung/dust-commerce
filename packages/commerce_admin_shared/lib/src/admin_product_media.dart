import 'package:dust_dart/serde.dart';

part 'admin_product_media.g.dart';

/// One uploaded asset attached to a product during atomic creation.
@Derive([ToString(), Eq(), Validate(), Serialize(), Deserialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminCreateProductMedia with _$AdminCreateProductMedia {
  /// Creates one ordered product-media input.
  const AdminCreateProductMedia({
    required this.id,
    required this.url,
    required this.isThumbnail,
  });

  /// Decodes the generated product-media input.
  factory AdminCreateProductMedia.fromJson(Map<String, Object?> json) =>
      _$AdminCreateProductMediaFromJson(json);

  /// Server-generated storage key returned by the upload endpoint.
  @Validate(length: Length(min: 1, max: 255), message: 'Choose an image')
  final String id;

  /// Whether this image is the product-card and cart thumbnail.
  final bool isThumbnail;

  /// Public URL returned with [id] by the upload endpoint.
  @Validate(length: Length(min: 1, max: 2048), message: 'Choose an image')
  final String url;
}
