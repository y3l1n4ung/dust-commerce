import 'package:admin_app/src/core/admin_api.dart';
import 'package:admin_app/src/product/admin_product_state.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
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

  /// Retires one product and refreshes the current server-owned page.
  Future<bool> delete(String id) async {
    final revision = ++_revision;
    final current = state;
    emit(current.copyWith(
      status: AdminProductStatus.loading,
      failure: const None(),
    ));
    try {
      await args.api.deleteProduct(id);
      if (revision != _revision) return true;
      final previousPage = current.products.length == 1 && current.offset > 0;
      await load(
        query: current.query,
        offset: previousPage ? current.offset - current.limit : current.offset,
      );
      return true;
    } on DioException catch (error) {
      if (revision != _revision) return false;
      _deleteFailed(
        current,
        error.response?.statusCode == 404
            ? 'This product no longer exists.'
            : error.response?.statusCode == 401
                ? 'Your admin session has expired.'
                : 'Unable to delete this product. Try again.',
      );
      return false;
    } on Object {
      if (revision != _revision) return false;
      _deleteFailed(current, 'Unable to delete this product. Try again.');
      return false;
    }
  }

  /// Loads the first page for [query].
  Future<void> search(String query) => load(query: query, offset: 0);

  /// Applies the selected lifecycle states and resets server paging.
  Future<void> filterByStatuses(List<AdminProductLifecycle> statuses) => load(
        statuses: List.unmodifiable(statuses.toSet()),
        offset: 0,
      );

  /// Applies one allowlisted server ordering and resets paging.
  Future<void> orderBy(AdminProductOrder order) => load(
        order: order,
        offset: 0,
      );

  /// Loads one bounded catalogue page.
  Future<void> load({
    String? query,
    int? offset,
    List<AdminProductLifecycle>? statuses,
    AdminProductOrder? order,
  }) async {
    final nextQuery = (query ?? state.query).trim();
    final nextOffset = (offset ?? state.offset).clamp(0, 1 << 31);
    final nextStatuses = statuses ?? state.statuses;
    final nextOrder = order ?? state.order;
    final revision = ++_revision;
    emit(AdminProductState(
      status: AdminProductStatus.loading,
      products: state.products,
      count: state.count,
      limit: state.limit,
      offset: nextOffset,
      query: nextQuery,
      statuses: nextStatuses,
      order: nextOrder,
    ));
    try {
      final result = await args.api.listProducts(
        nextQuery,
        nextStatuses.map((status) => status.name).join(','),
        nextOrder.parameter,
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
        statuses: nextStatuses,
        order: nextOrder,
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

  void _deleteFailed(AdminProductState current, String message) =>
      emit(current.copyWith(
        status: AdminProductStatus.ready,
        failure: Some(message),
      ));

  void _fail(String message) => emit(AdminProductState(
        status: AdminProductStatus.failed,
        products: state.products,
        count: state.count,
        limit: state.limit,
        offset: state.offset,
        query: state.query,
        statuses: state.statuses,
        order: state.order,
        failure: Some(message),
      ));
}
