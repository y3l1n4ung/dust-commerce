import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// Everything the cart handlers need, attached once with `withState`.
final class CartDeps {
  /// Creates a [CartDeps].
  const CartDeps({
    required this.creates,
    required this.reads,
    required this.lists,
    required this.writes,
    required this.catalog,
    required this.clock,
  });

  /// Finding a variant to add.
  final CatalogReadRepository catalog;

  /// The clock and the identifier source.
  final Clock clock;

  /// Starting a cart.
  final CartCreateRepository creates;

  /// What a region offers.
  final CartListRepository lists;

  /// Loading a cart and its lines.
  final CartReadRepository reads;

  /// Changing what it holds.
  final CartUpdateRepository writes;
}

/// The cart dependencies, or the 500 that says they were never attached.
Future<Result<CartDeps, Rejection>> cartDeps(Request request) =>
    stateOf<CartDeps>(request);
