import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/serde.dart';

part 'cart_state.g.dart';

/// The cart operation currently visible to the storefront.
enum CartStatus {
  /// No cart operation has started.
  idle,

  /// A cart request is in flight.
  loading,

  /// The latest cart request completed.
  ready,

  /// The latest cart request failed.
  failed,
}

/// The cart action whose progress the storefront is showing.
enum CartOperation {
  /// Restoring the persisted cart capability.
  restore,

  /// Adding a selected variant.
  add,

  /// Replacing one line quantity.
  update,

  /// Removing one line.
  remove,

  /// Applying or removing a promotion.
  promotion,

  /// Loading or choosing delivery.
  shipping,
}

/// The single cart shared by navigation, product actions, and checkout.
@Derive([ToString(), Eq(), CopyWith()])
class CartState with _$CartState {
  /// Creates cart state.
  const CartState({
    this.status = CartStatus.idle,
    this.cart,
    this.message,
    this.operation,
    this.activeLineId,
    this.shippingOptions = const [],
  });

  /// The server-computed cart and totals, once created.
  final CartView? cart;

  /// Line being updated or removed, when the action is line-scoped.
  final String? activeLineId;

  /// A display-safe operation failure.
  final String? message;

  /// The operation currently in flight or most recently failed.
  final CartOperation? operation;

  /// Delivery choices returned by the server for the current cart.
  final List<ShippingMethod> shippingOptions;

  /// The operation currently in flight.
  final CartStatus status;

  /// Quantity shown in navigation.
  int get itemCount => cart?.itemCount ?? 0;
}
