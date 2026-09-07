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

  /// Streams selected image files before they are attached to a product.
  @POST('/admin/uploads')
  @MultiPart()
  Future<AdminUploadedFileList> uploadMedia(
    @Part('files') List<MultipartFile> files,
  );

  /// Discards one staged upload that is not attached to a product.
  @DELETE('/admin/uploads/{id}')
  Future<void> deleteUpload(@Path() String id);

  /// Reads one complete merchant product detail.
  @GET('/admin/products/{id}')
  Future<AdminProductDetail> product(@Path() String id);

  /// Replaces supported general fields and returns refreshed detail.
  @PATCH('/admin/products/{id}')
  Future<AdminProductDetail> updateProduct(
    @Path() String id,
    @Body() AdminUpdateProduct body,
  );

  /// Replaces one product option's title, values, and display order.
  @PATCH('/admin/products/{id}/options/{optionId}')
  Future<AdminProductDetail> updateProductOption(
    @Path() String id,
    @Path() String optionId,
    @Body() AdminUpdateProductOption body,
  );

  /// Replaces one variant's Medusa detail-drawer fields.
  @PATCH('/admin/products/{id}/variants/{variantId}')
  Future<AdminProductDetail> updateProductVariant(
    @Path() String id,
    @Path() String variantId,
    @Body() AdminUpdateProductVariant body,
  );

  /// Replaces product image membership, order, and thumbnail atomically.
  @PUT('/admin/products/{id}/media')
  Future<AdminProductDetail> updateProductMedia(
    @Path() String id,
    @Body() AdminUpdateProductMedia body,
  );

  /// Adds and removes variant associations for one product image.
  @POST('/admin/products/{id}/images/{imageId}/variants/batch')
  Future<AdminBatchImageVariantsResult> batchImageVariants(
    @Path() String id,
    @Path() String imageId,
    @Body() AdminBatchImageVariants body,
  );

  /// Revokes the Dio-managed bearer.
  @DELETE('/auth/admin/session')
  Future<AdminSessionDeleted> signOut();
}
