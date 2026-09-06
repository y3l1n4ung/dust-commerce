import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/product/admin_product_state.dart';
import 'package:dio/dio.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/state.dart';

part 'admin_product_view_model.g.dart';

/// Dependencies for the authenticated merchant catalogue.
final class AdminProductViewModelArgs extends ViewModelArgs {
  /// Creates catalogue dependencies.
  const AdminProductViewModelArgs({required this.api, super.observer});

  /// Generated admin-only API client.
  final AdminApi api;
}

/// Loads and pages the merchant catalogue without widget-owned responses.
@ViewModel(state: AdminProductState, args: AdminProductViewModelArgs)
final class AdminProductViewModel extends $AdminProductViewModel {
  /// Creates the catalogue state machine.
  AdminProductViewModel(super.args);

  int _revision = 0;

  /// Loads the first page for [query].
  Future<void> search(String query) => load(query: query, offset: 0);

  /// Loads one bounded catalogue page.
  Future<void> load({String? query, int? offset}) async {
    final nextQuery = (query ?? state.query).trim();
    final nextOffset = (offset ?? state.offset).clamp(0, 1 << 31);
    final revision = ++_revision;
    emit(AdminProductState(
      status: AdminProductStatus.loading,
      products: state.products,
      count: state.count,
      limit: state.limit,
      offset: nextOffset,
      query: nextQuery,
    ));
    try {
      final result = await args.api.listProducts(
        nextQuery,
        state.limit,
        nextOffset,
      );
      if (revision != _revision) return;
      emit(AdminProductState(
        status: AdminProductStatus.ready,
        products: result.products,
        count: result.count,
        limit: result.limit,
        offset: result.offset,
        query: nextQuery,
      ));
    } on DioException catch (error) {
      if (revision != _revision) return;
      _fail(error.response?.statusCode == 401
          ? 'Your admin session has expired.'
          : 'Unable to load products. Try again.');
    } on Object {
      if (revision != _revision) return;
      _fail('Unable to load products. Try again.');
    }
  }

  /// Loads the preceding server page.
  Future<void> previous() =>
      load(offset: (state.offset - state.limit).clamp(0, 1 << 31));

  /// Loads the following server page.
  Future<void> next() => load(offset: state.offset + state.limit);

  void _fail(String message) => emit(AdminProductState(
        status: AdminProductStatus.failed,
        products: state.products,
        count: state.count,
        limit: state.limit,
        offset: state.offset,
        query: state.query,
        failure: Some(message),
      ));
}
