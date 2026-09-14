import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/http.dart';

part 'admin_customer_api.g.dart';

/// Generated customer API isolated from storefront contracts.
@HttpClient(
  baseUrl: 'http://localhost:3878',
  headers: {'accept': 'application/json'},
  target: HttpTarget.flutter,
)
abstract interface class AdminCustomerApi {
  /// Binds the customer client to Dio-managed authorization.
  factory AdminCustomerApi(Dio dio, {String? baseUrl}) = _$AdminCustomerApi;

  /// Lists merchant-visible customers using Medusa query parameters.
  @GET('/admin/customers')
  Future<AdminCustomerList> listCustomers(
    @Query('q') String query,
    @Query('has_account') String hasAccount,
    @Query('created_at') String createdAt,
    @Query('updated_at') String updatedAt,
    @Query('order') String order,
    @Query('limit') int limit,
    @Query('offset') int offset,
  );

  /// Reads one merchant-visible customer profile and active address book.
  @GET('/admin/customers/{id}')
  Future<AdminCustomerDetail> customer(@Path() String id);

  /// Lists only orders owned by one customer for the detail route.
  @GET('/admin/orders')
  Future<AdminOrderList> listCustomerOrders(
    @Query('customer_id') String customerId,
    @Query('q') String query,
    @Query('order') String order,
    @Query('limit') int limit,
    @Query('offset') int offset,
  );
}
