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
