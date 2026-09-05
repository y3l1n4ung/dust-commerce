import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/testing.dart';

/// Account setup used by generated-client integration tests.
extension AccountSetup on TestClient {
  /// Registers and signs in the fixed integration-test customer.
  Future<String> customerToken() async {
    (await (post('/store/customers')
              ..json({
                'email': 'ada@example.com',
                'password': 'correct horse battery staple',
                'first_name': 'Ada',
                'last_name': 'Lovelace',
              }))
            .send())
        .assertCreated();
    final signedIn = await (post('/auth/customer/emailpass')
          ..json({
            'email': 'ada@example.com',
            'password': 'correct horse battery staple',
          }))
        .send();
    signedIn.assertOk();
    return (signedIn.json! as Map<String, Object?>)['token']! as String;
  }
}

/// In-memory customer-session persistence for non-widget application tests.
final class MemoryAuthSessionStore implements AuthSessionStore {
  /// Current stored session.
  StoredAuthSession? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<StoredAuthSession?> read() async => value;

  @override
  Future<void> write(IssuedToken token) async {
    value = StoredAuthSession(
      token: token.token,
      expiresAt: DateTime.parse(token.expiresAt).toUtc(),
    );
  }
}

/// Creates a signed-out account model for routing tests.
AccountViewModel testAccount(CommerceApi api) => AccountViewModel(
      AccountViewModelArgs(api: api, sessions: MemoryAuthSessionStore()),
    );

/// In-memory cart capability persistence for non-widget application tests.
final class MemoryCartIdStore implements CartIdStore {
  /// Stored capabilities by account scope.
  final Map<String, String> values = {};

  @override
  Future<void> clear(String scope) async => values.remove(scope);

  @override
  Future<String?> read(String scope) async => values[scope];

  @override
  Future<void> write(String scope, String cartId) async {
    values[scope] = cartId;
  }
}

/// Creates an empty cart model for routing tests.
CartViewModel testCart(CommerceApi api, {MemoryCartIdStore? storage}) =>
    CartViewModel(
      CartViewModelArgs(
        api: api,
        cartIds: storage ?? MemoryCartIdStore(),
      ),
    );
