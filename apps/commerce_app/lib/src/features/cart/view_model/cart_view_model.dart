import 'package:commerce_app/src/core/api/api.dart';
import 'package:commerce_app/src/features/cart/model/cart_state.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/state.dart';

part 'cart_view_model.g.dart';

/// Dependencies for the storefront cart.
final class CartViewModelArgs extends ViewModelArgs {
  /// Creates cart dependencies.
  const CartViewModelArgs({required this.api, super.observer});

  /// The generated storefront client.
  final CommerceApi api;
}

/// Owns the real server cart used across storefront routes.
@ViewModel(state: CartState, args: CartViewModelArgs)
class CartViewModel extends $CartViewModel {
  /// Creates the cart view model.
  CartViewModel(super.args);

  /// Adds one selected variant, creating the cart only when needed.
  Future<bool> add(ProductVariant variant) async {
    if (state.status == CartStatus.loading) return false;
    var current = state.cart;
    emit(state.copyWith(status: CartStatus.loading, message: null));

    try {
      current ??= await args.api.createCart();
      current = await args.api.addLine(
        current.cart.id,
        AddLineBody(variantId: variant.id),
      );
      emit(CartState(status: CartStatus.ready, cart: current));
      return true;
    } on Object {
      emit(
        CartState(
          status: CartStatus.failed,
          cart: current,
          message: 'Could not update the cart. Please try again.',
        ),
      );
      return false;
    }
  }
}
