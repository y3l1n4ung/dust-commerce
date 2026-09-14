import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/http.dart';

part 'admin_customer_group_api.g.dart';

/// Generated customer-group API isolated from Store and customer contracts.
@HttpClient(
  baseUrl: 'http://localhost:3878',
  headers: {'accept': 'application/json'},
  target: HttpTarget.flutter,
)
abstract interface class AdminCustomerGroupApi {
  /// Binds the group client to Dio-managed authorization.
  factory AdminCustomerGroupApi(Dio dio, {String? baseUrl}) =
      _$AdminCustomerGroupApi;

  /// Creates one merchant customer segment.
  @POST('/admin/customer-groups')
  Future<AdminCustomerGroupCreateResponse> createCustomerGroup(
    @Body() AdminCreateCustomerGroup body,
  );

  /// Lists merchant-visible groups through Medusa query parameters.
  @GET('/admin/customer-groups')
  Future<AdminCustomerGroupList> listCustomerGroups(
    @Query('q') String query,
    @Query('created_at') String createdAt,
    @Query('updated_at') String updatedAt,
    @Query('order') String order,
    @Query('limit') int limit,
    @Query('offset') int offset,
  );
}
