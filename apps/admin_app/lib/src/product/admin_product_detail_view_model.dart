import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:dio/dio.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/state.dart';

part 'admin_product_detail_view_model.g.dart';

/// Dependencies for one authenticated merchant product detail.
final class AdminProductDetailViewModelArgs extends ViewModelArgs {
  /// Creates product detail dependencies.
  const AdminProductDetailViewModelArgs({required this.api, super.observer});

  /// Generated admin-only API client.
  final AdminApi api;
}

/// Loads one product without exposing Dio responses to widgets.
@ViewModel(
  state: AdminProductDetailState,
  args: AdminProductDetailViewModelArgs,
)
final class AdminProductDetailViewModel extends $AdminProductDetailViewModel {
  /// Creates the product detail state machine.
  AdminProductDetailViewModel(super.args);

  int _revision = 0;

  /// Loads the complete allowlisted detail for [id].
  Future<void> load(String id) async {
    final revision = ++_revision;
    emit(const AdminProductDetailState(
      status: AdminProductDetailStatus.loading,
    ));
    try {
      final product = await args.api.product(id);
      if (revision != _revision) return;
      emit(AdminProductDetailState(
        status: AdminProductDetailStatus.ready,
        product: Some(product),
      ));
    } on DioException catch (error) {
      if (revision != _revision) return;
      _fail(error.response?.statusCode == 404
          ? 'This product no longer exists.'
          : error.response?.statusCode == 401
              ? 'Your admin session has expired.'
              : 'Unable to load this product. Try again.');
    } on Object {
      if (revision != _revision) return;
      _fail('Unable to load this product. Try again.');
    }
  }

  void _fail(String message) => emit(AdminProductDetailState(
        status: AdminProductDetailStatus.failed,
        failure: Some(message),
      ));
}
