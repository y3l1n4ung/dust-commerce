import 'package:dust_dart/serde.dart';

/// JSON null maps to an explicit absent string in Admin contracts.
final class AdminOptionalStringCodec
    implements SerDeCodec<Option<String>, Object?> {
  /// Creates the stateless codec.
  const AdminOptionalStringCodec();

  @override
  Option<String> deserialize(Object? json) => switch (json) {
        null => const None(),
        final String value => Some(value),
        _ => throw FormatException('Expected a string or null'),
      };

  @override
  Object? serialize(Option<String> value) => switch (value) {
        Some(:final value) => value,
        None() => null,
      };
}

/// JSON null maps to an explicit absent integer in Admin contracts.
final class AdminOptionalIntCodec implements SerDeCodec<Option<int>, Object?> {
  /// Creates the stateless codec.
  const AdminOptionalIntCodec();

  @override
  Option<int> deserialize(Object? json) => switch (json) {
        null => const None(),
        final int value => Some(value),
        _ => throw FormatException('Expected an integer or null'),
      };

  @override
  Object? serialize(Option<int> value) => switch (value) {
        Some(:final value) => value,
        None() => null,
      };
}

/// ISO-8601 JSON null maps to an explicit absent instant.
final class AdminOptionalDateTimeCodec
    implements SerDeCodec<Option<DateTime>, Object?> {
  /// Creates the stateless codec.
  const AdminOptionalDateTimeCodec();

  @override
  Option<DateTime> deserialize(Object? json) => switch (json) {
        null => const None(),
        final String value => Some(DateTime.parse(value)),
        _ => throw FormatException('Expected an ISO-8601 string or null'),
      };

  @override
  Object? serialize(Option<DateTime> value) => switch (value) {
        Some(:final value) => value.toIso8601String(),
        None() => null,
      };
}
