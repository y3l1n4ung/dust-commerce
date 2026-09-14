part of 'admin_order_detail_view_model.dart';

/// Cancellation mutation kept separate from other order-detail operations.
extension AdminOrderCancellationMutation on AdminOrderDetailViewModel {
  /// Cancels one fulfillment and publishes the refreshed typed order.
  Future<bool> cancelFulfillment(
    String orderId,
    String fulfillmentId,
    AdminCancelFulfillment body,
  ) async {
    final revision = _beginSave();
    try {
      final order = await args.api.cancelFulfillment(
        orderId,
        fulfillmentId,
        body,
      );
      return _publishSaved(revision, order);
    } on DioException catch (error) {
      if (revision != _revision) return false;
      _saveFailure(switch (error.response?.statusCode) {
        401 => 'Your admin session has expired.',
        404 => 'This fulfillment no longer exists.',
        422 => 'Cancellation command is invalid.',
        503 => 'Fulfillment cancellation is unavailable.',
        _ => 'Unable to cancel this fulfillment. Try again.',
      });
      return false;
    } on Object {
      if (revision != _revision) return false;
      _saveFailure('Unable to cancel this fulfillment. Try again.');
      return false;
    }
  }
}
