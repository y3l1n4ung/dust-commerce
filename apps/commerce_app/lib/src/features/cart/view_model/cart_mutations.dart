part of 'cart_view_model.dart';

/// Server-authoritative mutations kept beside the generated cart state owner.
extension CartMutations on CartViewModel {
  /// Replaces one line quantity after the server rechecks inventory.
  Future<bool> updateQuantity(String lineId, int quantity) => _change(
        CartOperation.update,
        lineId: lineId,
        request: (id) => args.api.updateLine(
          id,
          lineId,
          UpdateLineBody(quantity: quantity),
        ),
      );

  /// Removes one line and accepts only the server's updated totals.
  Future<bool> remove(String lineId) => _change(
        CartOperation.remove,
        lineId: lineId,
        request: (id) => args.api.removeLine(id, lineId),
      );

  /// Loads delivery choices for the current cart.
  Future<bool> loadShippingOptions() async {
    final cart = state.cart;
    if (cart == null || !_begin(CartOperation.shipping)) return false;
    try {
      final view = await args.api.shippingOptions(cart.cart.id);
      _setShippingOptions(cart, view.shippingOptions);
      return true;
    } on Object catch (error) {
      _fail(CartOperation.shipping, error, cart: cart);
      return false;
    }
  }

  /// Selects delivery and accepts only the server's updated totals.
  Future<bool> chooseShipping(String optionId) => _change(
        CartOperation.shipping,
        request: (id) => args.api.chooseShipping(
          id,
          ChooseShippingBody(optionId: optionId),
        ),
      );

  /// Applies a promotion and accepts only the server's updated totals.
  Future<bool> applyPromotion(String code) => _change(
        CartOperation.promotion,
        request: (id) => args.api.applyPromotion(
          id,
          ApplyPromotionBody(code: code.trim()),
        ),
      );

  /// Removes the current promotion and accepts the server's totals.
  Future<bool> removePromotion() => _change(
        CartOperation.promotion,
        request: args.api.removePromotion,
      );

  Future<bool> _change(
    CartOperation operation, {
    String? lineId,
    required Future<CartView> Function(String cartId) request,
  }) async {
    final cart = state.cart;
    if (cart == null || !_begin(operation, lineId: lineId)) return false;
    try {
      return _succeed(await request(cart.cart.id));
    } on Object catch (error) {
      _fail(operation, error, cart: cart, lineId: lineId);
      return false;
    }
  }
}
