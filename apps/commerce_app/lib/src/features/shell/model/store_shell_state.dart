import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/serde.dart';

part 'store_shell_state.g.dart';

/// Loading lifecycle for taxonomy shared by the storefront shell.
enum StoreShellStatus {
  /// The shell has not requested its navigation data yet.
  idle,

  /// Collections and categories are loading concurrently.
  loading,

  /// Discovery finished; either list may legitimately be empty.
  ready,
}

/// Public taxonomy rendered by the shared Medusa-shaped footer.
@Derive([ToString(), Eq(), CopyWith()])
final class StoreShellState with _$StoreShellState {
  /// Creates immutable shell state.
  const StoreShellState({
    this.status = StoreShellStatus.idle,
    this.categories = const [],
    this.collections = const [],
  });

  /// Active public category nodes, including direct children.
  final List<ProductCategory> categories;

  /// Active public collections in server display order.
  final List<ProductCollection> collections;

  /// Current shared-navigation lifecycle.
  final StoreShellStatus status;
}
