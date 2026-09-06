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

  /// Reads one complete merchant product detail.
  @GET('/admin/products/{id}')
  Future<AdminProductDetail> product(@Path() String id);

  /// Revokes the Dio-managed bearer.
  @DELETE('/auth/admin/session')
  Future<AdminSessionDeleted> signOut();
}
