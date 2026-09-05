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

  /// Registers a customer account.
  @POST('/store/customers')
  Future<Customer> registerAccount(@Body() RegisterAccountBody body);

  /// Exchanges email/password credentials for a bearer token.
  @POST('/auth/customer/emailpass')
  Future<IssuedToken> signIn(@Body() Credentials body);

  /// Reads the customer proven by the bearer configured on the Dio client.
  @GET('/store/customers/me')
  Future<Customer> currentCustomer();

  /// Revokes the bearer token configured on the Dio client.
  @DELETE('/auth/session')
  Future<SessionDeleted> signOut();

  /// A page of the published catalogue.
  @GET('/store/products')
  Future<ProductPageView> products({
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
  Future<CartView> createCart();

  /// One cart with the totals the server computed.
  @GET('/store/carts/{id}')
  Future<CartView> cart(@Path() String id);

  /// Adds a variant to a cart, answering with the cart it produced.
  @POST('/store/carts/{id}/line-items')
  Future<CartView> addLine(
    @Path() String id,
    @Body() AddLineBody body,
  );

  /// Turns a cart into an order.
  @POST('/store/checkout')
  Future<Order> checkout(@Body() CheckoutRequest body);

  /// The authenticated customer's orders.
  @GET('/store/orders')
  Future<OrderListView> orders();

  /// One order owned by the authenticated customer.
  @GET('/store/orders/{id}')
  Future<Order> order(@Path() String id);
}
