import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/http.dart';

part 'admin_api.g.dart';

/// Generated client containing only merchant-admin operations.
@HttpClient(
  baseUrl: 'http://localhost:3878',
  headers: {'accept': 'application/json'},
  target: HttpTarget.flutter,
)
abstract interface class AdminApi {
  /// Binds the client to [dio].
  factory AdminApi(Dio dio, {String? baseUrl}) = _$AdminApi;

  /// Exchanges admin credentials for a bearer token.
  @POST('/auth/admin/emailpass')
  Future<AdminIssuedToken> signIn(@Body() AdminCredentials body);

  /// Reads the admin proven by Dio-managed authorization.
  @GET('/admin/users/me')
  Future<AdminUser> currentUser();

  /// Lists merchant-visible products with server-owned paging and search.
  @GET('/admin/products')
  Future<AdminProductList> listProducts(
    @Query('q') String query,
    @Query('limit') int limit,
    @Query('offset') int offset,
  );

  /// Loads active storefront currencies required by the creation grid.
  @GET('/admin/products/create-context')
  Future<AdminProductCreateContext> productCreateContext();

  /// Creates one complete product, option, variant, inventory, and price graph.
  @POST('/admin/products')
  Future<AdminProductDetail> createProduct(@Body() AdminCreateProduct body);

  /// Reads one complete merchant product detail.
  @GET('/admin/products/{id}')
  Future<AdminProductDetail> product(@Path() String id);

  /// Replaces supported general fields and returns refreshed detail.
  @PATCH('/admin/products/{id}')
  Future<AdminProductDetail> updateProduct(
    @Path() String id,
    @Body() AdminUpdateProduct body,
  );

  /// Revokes the Dio-managed bearer.
  @DELETE('/auth/admin/session')
  Future<AdminSessionDeleted> signOut();
}
