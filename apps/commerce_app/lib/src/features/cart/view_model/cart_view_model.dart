import 'package:commerce_app/src/core/api/api.dart';
import 'package:commerce_app/src/core/storage/storage.dart';
import 'package:commerce_app/src/features/cart/model/cart_state.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:dust_flutter/state.dart';

part 'cart_view_model.g.dart';
part 'cart_mutations.dart';

/// Dependencies for the storefront cart.
final class CartViewModelArgs extends ViewModelArgs {
  /// Creates cart dependencies.
  const CartViewModelArgs({
    required this.api,
    required this.cartIds,
    this.storageScope = 'guest',
    super.observer,
  });

  /// The generated storefront client.
  final CommerceApi api;

  /// Secure persistence for the opaque cart capability.
  final CartIdStore cartIds;

  /// Separates guest and authenticated customer carts.
  final String storageScope;
}

/// Owns the real server cart used across storefront routes.
@ViewModel(state: CartState, args: CartViewModelArgs)
class CartViewModel extends $CartViewModel {
  /// Creates the cart view model.
  CartViewModel(super.args);

  Future<void>? _restoreTask;

  @override
  Future<void> onInit() => restore();

  /// Restores the cart capability and refreshes it from the server.
  Future<void> restore({bool force = false}) {
    final active = _restoreTask;
    if (active != null) return active;
    if (!force &&
        (state.status == CartStatus.loading ||
            state.status == CartStatus.ready)) {
      return Future<void>.value();
    }
    final task = _restore();
    _restoreTask = task;
    return task.whenComplete(() => _restoreTask = null);
  }

  Future<void> _restore() async {
    emit(const CartState(
      status: CartStatus.loading,
      operation: CartOperation.restore,
    ));
    try {
      final id = await args.cartIds.read(args.storageScope);
      if (id == null) {
        emit(const CartState(status: CartStatus.ready));
        return;
      }
      emit(CartState(status: CartStatus.ready, cart: await args.api.cart(id)));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        await args.cartIds.clear(args.storageScope);
        emit(const CartState(status: CartStatus.ready));
        return;
      }
      _fail(CartOperation.restore, error);
    } on Object catch (error) {
      _fail(CartOperation.restore, error);
    }
  }

  /// Clears the completed cart locally without making order success fragile.
  Future<void> finishCheckout() async {
    try {
      await args.cartIds.clear(args.storageScope);
    } finally {
      emit(const CartState(status: CartStatus.ready));
    }
  }

  /// Adds one selected variant, creating and persisting a cart when needed.
  Future<bool> add(ProductVariant variant) async {
    if (!_begin(CartOperation.add)) return false;
    var current = state.cart;
    try {
      if (current == null) {
        current = await args.api.createCart();
        await args.cartIds.write(args.storageScope, current.cart.id);
      }
      return _succeed(
        await args.api.addLine(
          current.cart.id,
          AddLineBody(variantId: variant.id),
        ),
      );
    } on Object catch (error) {
      _fail(CartOperation.add, error, cart: current);
      return false;
    }
  }

  bool _begin(CartOperation operation, {String? lineId}) {
    if (state.status == CartStatus.loading) return false;
    emit(state.copyWith(
      status: CartStatus.loading,
      operation: operation,
      activeLineId: lineId,
      message: null,
    ));
    return true;
  }

  bool _succeed(CartView cart) {
    emit(CartState(
      status: CartStatus.ready,
      cart: cart,
      shippingOptions: state.shippingOptions,
    ));
    return true;
  }

  void _setShippingOptions(
    CartView cart,
    List<ShippingMethod> options,
  ) {
    emit(CartState(
      status: CartStatus.ready,
      cart: cart,
      shippingOptions: options,
    ));
  }

  void _fail(
    CartOperation operation,
    Object error, {
    CartView? cart,
    String? lineId,
  }) {
    emit(CartState(
      status: CartStatus.failed,
      cart: cart ?? state.cart,
      operation: operation,
      activeLineId: lineId,
      shippingOptions: state.shippingOptions,
      message: _messageOf(error),
    ));
  }

  static String _messageOf(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] is String) {
        return data['error']! as String;
      }
    }
    return 'Could not update the cart. Please try again.';
  }
}
