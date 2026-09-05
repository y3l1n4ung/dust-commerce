import 'package:commerce_server/src/features/account/extractor.dart';
import 'package:commerce_server/src/features/cart/deps.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';
import 'package:dust_server/server.dart';

/// A path cart proven accessible to this customer or guest request.
final class CartAccess {
  /// Creates the route-level cart capability.
  const CartAccess({required this.cart, this.customer});

  /// The cart already loaded while enforcing access.
  final Cart cart;

  /// The authenticated customer, when one was supplied.
  final AuthenticatedCustomer? customer;
}

/// Loads a path cart and hides customer-owned carts from every other caller.
final class CartAccessExtractor implements FromRequestParts<CartAccess> {
  /// Creates the stateless route guard.
  const CartAccessExtractor();

  @override
  Future<Result<CartAccess, Rejection>> extract(Request request) async {
    final auth = await const OptionalCustomerAuth().extract(request);
    if (auth case Err(:final error)) return Err(error);

    final id = pathParametersOf(request)['id'];
    if (id == null || id.isEmpty) {
      return const Err(Rejection.badRequest('A cart id is required'));
    }
    final state = await const StateExtractable<CartDeps>().extract(request);
    if (state case Err(:final error)) return Err(error);
    final deps = (state as Ok<CartDeps, Rejection>).value;
    final loaded = await loadCart(deps.reads, id);
    if (loaded case Err()) return const Err(Rejection.internal());

    final cart = (loaded as Ok<Cart?, SqlxError>).value;
    final context = (auth as Ok<CustomerContext, Rejection>).value;
    final customer = context.authenticated;
    if (cart == null ||
        (cart.customerId != null && cart.customerId != customer?.customer.id)) {
      return Err(Rejection.notFound('Cart "$id"'));
    }
    return Ok(CartAccess(cart: cart, customer: customer));
  }
}
