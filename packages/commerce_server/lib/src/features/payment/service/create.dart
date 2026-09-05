import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_server/src/features/checkout/model.dart';
import 'package:commerce_server/src/features/checkout/service/service.dart';
import 'package:commerce_server/src/features/payment/repository/repository.dart';
import 'package:commerce_server/src/infra/option.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Why a payment could not be started.
enum AuthorizeFailure {
  /// No order with that id, or not this caller's.
  noOrder,

  /// The order was cancelled, so there is nothing to pay.
  cancelled,

  /// A payment has already been started for this order.
  alreadyStarted,
}

/// Starts a payment for [orderId], for the amount the order says.
///
/// The amount comes from the stored order total, never from the request. A
/// client that could name the amount could name a smaller one.
Future<Result<Result<OrderResponse, AuthorizeFailure>, SqlxError>>
    authorizePayment(
  CheckoutReadRepository orders,
  PaymentReadRepository reads,
  PaymentCreateRepository writes, {
  required String orderId,
  required String email,
  required Option<String> customerId,
  required String id,
  String provider = 'manual',
}) async {
  final loaded = await loadOrder(orders, orderId);
  if (loaded case Err(:final error)) return Err(error);

  final orderOption = (loaded as Ok<Option<OrderResponse>, SqlxError>).value;
  if (orderOption case None()) {
    return const Ok(Err(AuthorizeFailure.noOrder));
  }
  final order = (orderOption as Some<OrderResponse>).value;
  final ownsOrder = switch (order.customerId) {
    null => order.email == email,
    final owner => customerId == Some(owner),
  };
  if (!ownsOrder) {
    return const Ok(Err(AuthorizeFailure.noOrder));
  }
  if (order.status == OrderStatus.cancelled) {
    return const Ok(Err(AuthorizeFailure.cancelled));
  }

  final existing = await reads.forOrder(orderId);
  if (existing case Err(:final error)) return Err(error);
  final payment = optionOf((existing as Ok<String?, SqlxError>).value);
  if (payment case Some()) {
    return const Ok(Err(AuthorizeFailure.alreadyStarted));
  }

  final written = await writes.authorize(
    id,
    orderId,
    provider,
    order.total.amount,
    order.total.currencyCode,
  );
  if (written case Err(:final error)) return Err(error);

  return Ok(Ok(order));
}
