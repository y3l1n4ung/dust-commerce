import 'package:commerce_server/commerce_server.dart';
import 'package:dust_server/server.dart';
import 'package:test/test.dart';

void main() {
  test('browser cart quantity preflight allows PATCH', () async {
    const origin = 'http://127.0.0.1:13000';
    final handler = storefrontCors({origin}).toMiddleware()(
      (_) async => Response.ok('preflight must not reach the handler'),
    );

    final response = await handler(
      Request(
        'OPTIONS',
        Uri.parse('http://localhost/store/carts/cart/line-items/line'),
        headers: const {
          'origin': origin,
          'access-control-request-method': 'PATCH',
          'access-control-request-headers': 'content-type',
        },
      ),
    );

    expect(response.statusCode, 204);
    expect(response.headers['access-control-allow-origin'], origin);
    expect(
      response.headers['access-control-allow-methods']?.split(', '),
      contains('PATCH'),
    );
  });
}
