import 'package:commerce_app/src/core/api/api.dart';
import 'package:commerce_app/src/features/product/model/product_state.dart';
import 'package:dust_flutter/state.dart';

part 'product_view_model.g.dart';

/// Dependencies for product details.
final class ProductViewModelArgs extends ViewModelArgs {
  /// Creates product dependencies.
  const ProductViewModelArgs({required this.api, super.observer});

  /// The generated storefront client.
  final CommerceApi api;
}

/// Loads a product and resolves its selected option combination.
@ViewModel(state: ProductDetailState, args: ProductViewModelArgs)
class ProductViewModel extends $ProductViewModel {
  /// Creates the product view model.
  ProductViewModel(super.args);

  /// Loads the product addressed by [handle].
  Future<void> load(
    String handle, {
    String currency = 'usd',
    String? variantId,
  }) async {
    emit(const ProductDetailState(status: ProductDetailStatus.loading));
    try {
      final product = await args.api.product(handle, currency: currency);
      emit(
        ProductDetailState(
          status: ProductDetailStatus.ready,
          product: product,
          selection: product.variantById(variantId ?? '')?.optionValues ?? {},
        ),
      );
    } on Object {
      emit(
        const ProductDetailState(
          status: ProductDetailStatus.failed,
          message: 'Could not load this product. Please try again.',
        ),
      );
    }
  }

  /// Selects one value for a product option.
  void select(String optionId, String value) {
    if (!state.canSelect(optionId, value)) return;
    emit(state.copyWith(selection: {...state.selection, optionId: value}));
  }
}
