import 'package:commerce_server/src/features/checkout/failure.dart';
import 'package:commerce_server/src/features/checkout/model.dart';

/// Transaction outcome keeps business refusal outside SQLx's error channel.
sealed class CheckoutPlacementOutcome {
  const CheckoutPlacementOutcome();
}

/// Successful committed order.
final class CheckoutPlacementReady extends CheckoutPlacementOutcome {
  /// Creates a successful placement outcome.
  const CheckoutPlacementReady(this.order);

  /// Direct SQLx order response.
  final OrderResponse order;
}

/// Expected refusal that causes the transaction to commit no order.
final class CheckoutPlacementDenied extends CheckoutPlacementOutcome {
  /// Creates a denied placement outcome.
  const CheckoutPlacementDenied(this.failure);

  /// Stable checkout refusal.
  final CheckoutFailure failure;
}
