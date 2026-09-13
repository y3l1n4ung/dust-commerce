import 'package:admin_app/src/order/admin_order_detail_api.dart';
import 'package:admin_app/src/order/admin_order_detail_state.dart';
import 'package:dio/dio.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/state.dart';

part 'admin_order_detail_view_model.g.dart';

/// Dependencies for one authenticated merchant order detail.
final class AdminOrderDetailViewModelArgs extends ViewModelArgs {
  /// Creates order-detail dependencies.
  const AdminOrderDetailViewModelArgs({required this.api, super.observer});

  /// Generated order-detail API using Dio-level authorization.
  final AdminOrderDetailApi api;
}

/// Loads one frozen order without exposing transport objects to widgets.
@ViewModel(
  state: AdminOrderDetailState,
  args: AdminOrderDetailViewModelArgs,
)
final class AdminOrderDetailViewModel extends $AdminOrderDetailViewModel {
  /// Creates the order-detail state machine.
  AdminOrderDetailViewModel(super.args);

  int _revision = 0;

  /// Loads the complete allowlisted detail for [id].
  Future<void> load(String id) async {
    final revision = ++_revision;
    emit(const AdminOrderDetailState(status: AdminOrderDetailStatus.loading));
    try {
      final order = await args.api.order(id);
      if (revision != _revision) return;
      emit(AdminOrderDetailState(
        status: AdminOrderDetailStatus.ready,
        order: Some(order),
      ));
    } on DioException catch (error) {
      if (revision != _revision) return;
      _fail(switch (error.response?.statusCode) {
        404 => 'This order no longer exists.',
        401 => 'Your admin session has expired.',
        _ => 'Unable to load this order. Try again.',
      });
    } on Object {
      if (revision != _revision) return;
      _fail('Unable to load this order. Try again.');
    }
  }

  void _fail(String message) => emit(AdminOrderDetailState(
        status: AdminOrderDetailStatus.failed,
        failure: Some(message),
      ));
}
