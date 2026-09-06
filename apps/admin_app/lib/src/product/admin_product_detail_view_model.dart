import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
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

  /// Replaces supported general fields and publishes the refreshed response.
  Future<bool> update(String id, AdminUpdateProduct input) async {
    final current = state.product;
    emit(AdminProductDetailState(
      status: AdminProductDetailStatus.saving,
      product: current,
    ));
    try {
      final product = await args.api.updateProduct(id, input);
      emit(AdminProductDetailState(
        status: AdminProductDetailStatus.ready,
        product: Some(product),
      ));
      return true;
    } on DioException catch (error) {
      final message = switch (error.response?.statusCode) {
        409 => 'This handle is already in use.',
        422 => 'Check the product details and try again.',
        404 => 'This product no longer exists.',
        401 => 'Your admin session has expired.',
        _ => 'Unable to save this product. Try again.',
      };
      emit(AdminProductDetailState(
        status: AdminProductDetailStatus.ready,
        product: current,
        failure: Some(message),
      ));
      return false;
    } on Object {
      emit(AdminProductDetailState(
        status: AdminProductDetailStatus.ready,
        product: current,
        failure: const Some('Unable to save this product. Try again.'),
      ));
      return false;
    }
  }

  /// Streams image files for the media editor without exposing Dio responses.
  Future<Option<List<AdminUploadedFile>>> uploadMedia(
    List<MultipartFile> files,
  ) async {
    if (files.isEmpty) return const None();
    final current = state.product;
    emit(AdminProductDetailState(
      status: AdminProductDetailStatus.saving,
      product: current,
    ));
    try {
      final uploaded = await args.api.uploadMedia(files);
      emit(AdminProductDetailState(
        status: AdminProductDetailStatus.ready,
        product: current,
      ));
      return Some(uploaded.files);
    } on DioException catch (error) {
      _updateFailed(
          current,
          switch (error.response?.statusCode) {
            413 => 'Each image must be 5 MB or smaller.',
            415 || 422 => 'Choose JPEG, PNG, GIF, or WebP image files.',
            401 => 'Your admin session has expired.',
            503 => 'Product media storage is not configured.',
            _ => 'Unable to upload these images. Try again.',
          });
      return const None();
    } on Object {
      _updateFailed(current, 'Unable to upload these images. Try again.');
      return const None();
    }
  }

  /// Persists complete gallery membership, order, and thumbnail.
  Future<bool> updateMedia(String id, AdminUpdateProductMedia input) async {
    final current = state.product;
    emit(AdminProductDetailState(
      status: AdminProductDetailStatus.saving,
      product: current,
    ));
    try {
      final product = await args.api.updateProductMedia(id, input);
      emit(AdminProductDetailState(
        status: AdminProductDetailStatus.ready,
        product: Some(product),
      ));
      return true;
    } on DioException catch (error) {
      _updateFailed(
          current,
          switch (error.response?.statusCode) {
            422 => 'Check the product images and try again.',
            404 => 'This product no longer exists.',
            401 => 'Your admin session has expired.',
            _ => 'Unable to save product media. Try again.',
          });
      return false;
    } on Object {
      _updateFailed(current, 'Unable to save product media. Try again.');
      return false;
    }
  }

  /// Deletes one newly uploaded file before the gallery is saved.
  Future<bool> discardUpload(String id) async {
    try {
      await args.api.deleteUpload(id);
      return true;
    } on Object {
      _updateFailed(state.product, 'Unable to remove this image. Try again.');
      return false;
    }
  }

  /// Clears a drawer-scoped failure without discarding loaded product data.
  void clearFailure() => emit(AdminProductDetailState(
        status: state.status,
        product: state.product,
      ));

  void _updateFailed(Option<AdminProductDetail> product, String message) =>
      emit(AdminProductDetailState(
        status: AdminProductDetailStatus.ready,
        product: product,
        failure: Some(message),
      ));

  void _fail(String message) => emit(AdminProductDetailState(
        status: AdminProductDetailStatus.failed,
        failure: Some(message),
      ));
}
