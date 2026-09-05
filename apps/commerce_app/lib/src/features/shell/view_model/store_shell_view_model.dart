import 'package:commerce_app/src/core/api/api.dart';
import 'package:commerce_app/src/features/shell/model/store_shell_state.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/state.dart';

part 'store_shell_view_model.g.dart';

/// Dependencies for taxonomy shared by every main-store route.
final class StoreShellViewModelArgs extends ViewModelArgs {
  /// Creates shell dependencies.
  const StoreShellViewModelArgs({required this.api, super.observer});

  /// Store API used for public navigation discovery.
  final CommerceApi api;
}

/// Loads the footer taxonomy once without making page content depend on it.
@ViewModel(state: StoreShellState, args: StoreShellViewModelArgs)
class StoreShellViewModel extends $StoreShellViewModel {
  /// Creates the shared shell state machine.
  StoreShellViewModel(super.args);

  /// Loads independent collection and category inventories concurrently.
  Future<void> load() async {
    if (state.status == StoreShellStatus.loading) return;
    emit(state.copyWith(status: StoreShellStatus.loading));
    final collections = _collections();
    final categories = _categories();
    emit(StoreShellState(
      status: StoreShellStatus.ready,
      collections: await collections,
      categories: await categories,
    ));
  }

  Future<List<ProductCollection>> _collections() async {
    try {
      return (await args.api.collections(limit: 100)).collections;
    } on Exception {
      // Footer discovery never replaces working page content with an error.
      return const [];
    }
  }

  Future<List<ProductCategory>> _categories() async {
    try {
      return (await args.api.categories(limit: 100)).categories;
    } on Exception {
      // Each column fails independently, matching the optional source blocks.
      return const [];
    }
  }
}
