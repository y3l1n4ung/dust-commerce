import 'package:commerce_app/src/core/api/responses.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/http.dart';

part 'commerce_api.g.dart';

/// The storefront API, generated from this declaration.
///
/// Every type crossing the wire here — [Product], [Cart], [Order], [Money] —
/// is the same class the server encodes with. Both ends are generated from one
/// definition in `commerce_shared`, so a field renamed there is a compile error
/// on both sides rather than a mismatch discovered at runtime.
///
/// The base URL is a development default and is overridden per environment
/// through the factory.
@HttpClient(
  baseUrl: 'http://localhost:8080',
  headers: {'accept': 'application/json'},
  target: HttpTarget.flutter,
)
abstract interface class CommerceApi {
  /// Binds the client to [dio], optionally against another [baseUrl].
  factory CommerceApi(Dio dio, {String? baseUrl}) = _$CommerceApi;

  /// A page of the published catalogue.
  @GET('/store/products')
  Future<ProductPageResponse> products({
    @Query('currency') String? currency,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// One product by the handle the storefront routes on.
  @GET('/store/products/{handle}')
  Future<Product> product(
    @Path() String handle, {
    @Query('currency') String? currency,
  });

  /// Starts an empty cart.
  @POST('/store/carts')
  Future<Cart> createCart();

  /// One cart with the totals the server computed.
  @GET('/store/carts/{id}')
  Future<CartResponse> cart(@Path() String id);

  /// Adds a variant to a cart, answering with the cart it produced.
  @POST('/store/carts/{id}/line-items')
  Future<CartResponse> addLine(
    @Path() String id,
    @Body() AddLineRequest body,
  );

  /// Turns a cart into an order.
  @POST('/store/checkout')
  Future<Order> checkout(@Body() CheckoutRequest body);

  /// The orders placed by one email address.
  @GET('/store/orders')
  Future<OrderListResponse> orders({@Query('email') required String email});

  /// One order, which the caller must prove the email of.
  @GET('/store/orders/{id}')
  Future<Order> order(
    @Path() String id, {
    @Query('email') required String email,
  });
}
