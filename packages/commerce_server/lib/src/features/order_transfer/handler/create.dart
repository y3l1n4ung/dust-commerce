import 'package:commerce_server/src/features/account/extractor.dart';
import 'package:commerce_server/src/features/order_transfer/deps.dart';
import 'package:commerce_server/src/features/order_transfer/model.dart';
import 'package:commerce_server/src/features/order_transfer/service/service.dart';
import 'package:dust_server/server.dart';

/// `POST /orders/{id}/transfer/request` — ask the current contact to approve.
Future<Result<OrderTransferResponse, Rejection>> requestOrderTransferHandler(
  Request request,
) async {
  final orderId = pathParametersOf(request)['id'];
  if (orderId == null || orderId.isEmpty) {
    return const Err(Rejection.badRequest('An order id is required'));
  }
  final actor = await request.extract(
    const Extension<AuthenticatedCustomer>(),
  );
  final state = await orderTransferDeps(request);
  if (state case Err(:final error)) return Err(error);
  final deps = (state as Ok<OrderTransferDeps, Rejection>).value;
  final result = await requestOrderTransfer(
    deps,
    orderId: orderId,
    customerId: actor.customer.id,
  );

  return switch (result) {
    Ok(value: Ok(value: final transfer)) => Ok(transfer),
    Ok(value: Err(error: RequestOrderTransferFailure.noOrder)) =>
      Err(Rejection.notFound('Order "$orderId"')),
    Ok(value: Err(error: RequestOrderTransferFailure.cancelled)) => const Err(
        Rejection.status(422, 'A cancelled order cannot be transferred'),
      ),
    Ok(value: Err(error: RequestOrderTransferFailure.alreadyOwner)) =>
      const Err(Rejection.status(422, 'This account already owns the order')),
    Ok(
      value: Err(
        error: RequestOrderTransferFailure.activeForAnotherCustomer,
      )
    ) =>
      const Err(
        Rejection.conflict('Another transfer request is already active'),
      ),
    Ok(value: Err(error: RequestOrderTransferFailure.deliveryUnavailable)) =>
      const Err(Rejection.status(
        503,
        'Order transfer email is not configured',
      )),
    Err() => const Err(Rejection.internal()),
  };
}
