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

/// The single cart shared by navigation, product actions, and checkout.
@Derive([ToString(), Eq(), CopyWith()])
class CartState with _$CartState {
  /// Creates cart state.
  const CartState({
    this.status = CartStatus.idle,
    this.cart,
    this.message,
  });

  /// The server-computed cart and totals, once created.
  final CartView? cart;

  /// A display-safe operation failure.
  final String? message;

  /// The operation currently in flight.
  final CartStatus status;

  /// Quantity shown in navigation.
  int get itemCount => cart?.itemCount ?? 0;
}
