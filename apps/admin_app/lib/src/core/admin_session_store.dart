import 'dart:convert';

import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secret session value kept outside serializable view-model state.
final class StoredAdminSession {
  /// Creates the private stored value.
  const StoredAdminSession({required this.token, required this.expiresAt});

  /// Restores one complete value or throws for malformed storage.
  factory StoredAdminSession.fromJson(Map<String, Object?> json) {
    final token = json['token'];
    final expiresAt = json['expires_at'];
    if (token is! String || token.isEmpty || expiresAt is! String) {
      throw const FormatException('Invalid stored admin session');
    }
    return StoredAdminSession(
      token: token,
      expiresAt: DateTime.parse(expiresAt).toUtc(),
    );
  }

  /// Server-issued UTC expiry.
  final DateTime expiresAt;

  /// Raw bearer used only by the authorization interceptor.
  final String token;

  /// Whether the bearer can no longer be sent at [now].
  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now.toUtc());
}

/// Session persistence contract with a memory fake used by unit tests.
abstract interface class AdminSessionStore {
  /// Removes the local bearer.
  Future<void> clear();

  /// Reads a complete session when present.
  Future<Option<StoredAdminSession>> read();

  /// Atomically writes one server-issued session.
  Future<void> write(AdminIssuedToken token);
}

/// Platform-secure admin session persistence.
final class SecureAdminSessionStore implements AdminSessionStore {
  /// Creates the secure store.
  SecureAdminSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'morrow.admin.auth.session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() => _storage.delete(key: _key);

  @override
  Future<Option<StoredAdminSession>> read() async {
    final encoded = await _storage.read(key: _key);
    if (encoded == null) return const None<StoredAdminSession>();
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, Object?>) throw const FormatException();
      return Some(StoredAdminSession.fromJson(value));
    } on FormatException {
      await clear();
      return const None<StoredAdminSession>();
    }
  }

  @override
  Future<void> write(AdminIssuedToken token) => _storage.write(
        key: _key,
        value: jsonEncode({
          'token': token.token,
          'expires_at': token.expiresAt.toUtc().toIso8601String(),
        }),
      );
}
