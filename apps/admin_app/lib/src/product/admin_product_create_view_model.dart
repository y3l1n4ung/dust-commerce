import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/product/admin_product_create_state.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dio/dio.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/state.dart';

part 'admin_product_create_view_model.g.dart';

/// Dependencies for authenticated product creation.
final class AdminProductCreateViewModelArgs extends ViewModelArgs {
  /// Creates product creation dependencies.
  const AdminProductCreateViewModelArgs({required this.api, super.observer});

  /// Generated admin-only client with Dio-owned authorization.
  final AdminApi api;
}

/// Loads create context and commits one complete merchant product graph.
@ViewModel(
  state: AdminProductCreateState,
  args: AdminProductCreateViewModelArgs,
)
final class AdminProductCreateViewModel extends $AdminProductCreateViewModel {
  /// Creates the product creation state machine.
  AdminProductCreateViewModel(super.args);

  /// Loads active storefront currencies before exposing price inputs.
  Future<void> load() async {
    emit(const AdminProductCreateState(
      status: AdminProductCreateStatus.loading,
    ));
    try {
      final context = await args.api.productCreateContext();
      if (context.currencyCodes.isEmpty) {
        _fail('Configure an active selling region before creating products.');
        return;
      }
      emit(AdminProductCreateState(
        status: AdminProductCreateStatus.ready,
        currencyCodes: context.currencyCodes,
      ));
    } on DioException catch (error) {
      _fail(error.response?.statusCode == 401
          ? 'Your admin session has expired.'
          : 'Unable to prepare product creation. Try again.');
    } on Object {
      _fail('Unable to prepare product creation. Try again.');
    }
  }

  /// Persists [input] and retains the explicit created-product allowlist.
  Future<Option<AdminProductDetail>> create(AdminCreateProduct input) async {
    final currencies = state.currencyCodes;
    emit(AdminProductCreateState(
      status: AdminProductCreateStatus.saving,
      currencyCodes: currencies,
    ));
    try {
      final product = await args.api.createProduct(input);
      emit(AdminProductCreateState(
        status: AdminProductCreateStatus.ready,
        currencyCodes: currencies,
        created: Some(product),
      ));
      return Some(product);
    } on DioException catch (error) {
      final message = switch (error.response?.statusCode) {
        409 => 'That handle or SKU is already in use.',
        422 => 'Check the options, variants, and regional prices.',
        401 => 'Your admin session has expired.',
        _ => 'Unable to create this product. Try again.',
      };
      _createFailed(currencies, message);
      return const None();
    } on Object {
      _createFailed(currencies, 'Unable to create this product. Try again.');
      return const None();
    }
  }

  /// Clears form-scoped errors without discarding loaded currencies.
  void clearFailure() => emit(AdminProductCreateState(
        status: AdminProductCreateStatus.ready,
        currencyCodes: state.currencyCodes,
      ));

  void _createFailed(List<String> currencies, String message) => emit(
        AdminProductCreateState(
          status: AdminProductCreateStatus.ready,
          currencyCodes: currencies,
          failure: Some(message),
        ),
      );

  void _fail(String message) => emit(AdminProductCreateState(
        status: AdminProductCreateStatus.failed,
        failure: Some(message),
      ));
}
