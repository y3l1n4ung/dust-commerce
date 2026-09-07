part of 'admin_product_detail_view_model.dart';

/// Product-option operations kept separate from the detail loader.
extension AdminProductDetailOptionActions on AdminProductDetailViewModel {
  /// Replaces one option and publishes the refreshed product response.
  Future<bool> updateOption(
    String productId,
    String optionId,
    AdminUpdateProductOption input,
  ) async {
    final current = state.product;
    _emitOption(AdminProductDetailState(
      status: AdminProductDetailStatus.saving,
      product: current,
    ));
    try {
      final product = await args.api.updateProductOption(
        productId,
        optionId,
        input,
      );
      _emitOption(AdminProductDetailState(
        status: AdminProductDetailStatus.ready,
        product: Some(product),
      ));
      return true;
    } on DioException catch (error) {
      _updateFailed(
        current,
        switch (error.response?.statusCode) {
          409 => _optionConflictMessage(error.response?.data),
          422 => 'Use unique, non-empty option values.',
          404 => 'This product option no longer exists.',
          401 => 'Your admin session has expired.',
          _ => 'Unable to save this product option. Try again.',
        },
      );
      return false;
    } on Object {
      _updateFailed(current, 'Unable to save this product option. Try again.');
      return false;
    }
  }
}

String _optionConflictMessage(Object? body) => switch (body) {
      {'error': 'Another option already uses this title'} =>
        'Another option already uses this title.',
      _ => 'A product variant still uses one of these values.',
    };
