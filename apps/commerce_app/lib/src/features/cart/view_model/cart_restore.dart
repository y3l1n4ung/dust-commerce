part of 'cart_view_model.dart';

/// Persisted-cart recovery and checkout completion.
extension CartRestore on CartViewModel {
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
    _setState(const CartState(
      status: CartStatus.loading,
      operation: CartOperation.restore,
    ));
    CartView? restored;
    try {
      final id = await args.cartIds.read(args.storageScope);
      if (id == null) {
        _setState(const CartState(status: CartStatus.ready));
        return;
      }
      restored = await args.api.cart(id);
      final selected = args.selectedRegion();
      if (selected case Some(value: final region)
          when restored.cart.region.id != region.id) {
        restored = await args.api.updateCartRegion(
          id,
          UpdateCartRegionBody(regionId: region.id),
        );
      }
      await _succeed(restored);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        await args.cartIds.clear(args.storageScope);
        _setState(const CartState(status: CartStatus.ready));
        return;
      }
      _fail(CartOperation.restore, error, cart: restored);
    } on Object catch (error) {
      _fail(CartOperation.restore, error, cart: restored);
    }
  }

  /// Clears the completed cart locally without making order success fragile.
  Future<void> finishCheckout() async {
    try {
      await args.cartIds.clear(args.storageScope);
    } finally {
      _setState(const CartState(status: CartStatus.ready));
    }
  }
}
