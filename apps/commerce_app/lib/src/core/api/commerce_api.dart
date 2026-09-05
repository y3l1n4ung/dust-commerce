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
    @Query('collection') String? collection,
    @Query('category') String? category,
    @Query('tag') String? tag,
    @Query('optionValueIds') List<String> optionValueIds = const [],
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Active stable option values used by the store refinement sidebar.
  @GET('/store/product-options')
  Future<ProductOptionFilterListView> productOptions({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Public collections used by featured rails and collection routes.
  @GET('/store/collections')
  Future<ProductCollectionListView> collections({
    @Query('handle') String? handle,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Public active category nodes used by nested category routes.
  @GET('/store/product-categories')
  Future<ProductCategoryListView> categories({
    @Query('handle') String? handle,
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

  /// Replaces one line's quantity after the server rechecks stock.
  @PATCH('/store/carts/{id}/line-items/{lineId}')
  Future<CartView> updateLine(
    @Path() String id,
    @Path() String lineId,
    @Body() UpdateLineBody body,
  );

  /// Removes one line and returns the server's new totals.
  @DELETE('/store/carts/{id}/line-items/{lineId}')
  Future<CartView> removeLine(
    @Path() String id,
    @Path() String lineId,
  );

  /// Delivery choices currently available to a cart.
  @GET('/store/carts/{id}/shipping-options')
  Future<ShippingOptionsView> shippingOptions(@Path() String id);

  /// Selects one delivery choice and returns authoritative totals.
  @POST('/store/carts/{id}/shipping-method')
  Future<CartView> chooseShipping(
    @Path() String id,
    @Body() ChooseShippingBody body,
  );

  /// Applies one promotion code and returns authoritative totals.
  @POST('/store/carts/{id}/promotions')
  Future<CartView> applyPromotion(
    @Path() String id,
    @Body() ApplyPromotionBody body,
  );

  /// Removes the cart's promotion and returns authoritative totals.
  @DELETE('/store/carts/{id}/promotions')
  Future<CartView> removePromotion(@Path() String id);

  /// Turns a cart into an order.
  @POST('/store/checkout')
  Future<Order> checkout(@Body() CheckoutRequest body);

  /// Starts the server-owned manual payment for an order.
  @POST('/store/orders/{id}/payments')
  Future<Order> authorizePayment(
    @Path() String id, {
    @Query('email') String? guestEmail,
  });

  /// Captures an authorized manual payment exactly once.
  @POST('/store/orders/{id}/payments/capture')
  Future<Order> capturePayment(
    @Path() String id, {
    @Query('email') String? guestEmail,
  });

  /// The authenticated customer's orders.
  @GET('/store/orders')
  Future<OrderListView> orders();

  /// One order owned by the authenticated customer.
  @GET('/store/orders/{id}')
  Future<Order> order(@Path() String id);
}
