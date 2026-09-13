import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/http.dart';

part 'admin_order_detail_api.g.dart';

/// Generated client for the protected Admin order-detail boundary.
@HttpClient(
  baseUrl: 'http://localhost:3878',
  headers: {'accept': 'application/json'},
  target: HttpTarget.flutter,
)
abstract interface class AdminOrderDetailApi {
  /// Binds the client to the Dio instance that owns authorization.
  factory AdminOrderDetailApi(Dio dio, {String? baseUrl}) =
      _$AdminOrderDetailApi;

  /// Reads one complete merchant-visible order snapshot.
  @GET('/admin/orders/{id}')
  Future<AdminOrderDetail> order(@Path() String id);

  /// Creates one fulfillment and returns the refreshed merchant order.
  @POST('/admin/orders/{id}/fulfillments')
  Future<AdminOrderDetail> createFulfillment(
    @Path() String id,
    @Body() AdminCreateFulfillment body,
  );
}
