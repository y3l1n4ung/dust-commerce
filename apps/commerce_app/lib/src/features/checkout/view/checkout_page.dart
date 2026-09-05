import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:flutter/material.dart';

import 'checkout_layout.dart';
import 'checkout_scaffold.dart';

/// Medusa-compatible public checkout guarded by a live cart capability.
@AppRoute('/checkout', name: 'checkout', guards: [CheckoutGuard])
final class CheckoutPage extends StatefulWidget {
  /// Creates the checkout route.
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _deliveryLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.readCheckoutViewModel().prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkout = context.watchCheckoutViewModel().value;
    final cart = context.watchCartViewModel().value;
    final view = cart.cart;
    if (view == null || checkout.status == CheckoutStatus.idle) {
      return const CheckoutScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final requested = context.checkoutStep;
    final step = _availableStep(requested, checkout, cart);
    if (step != requested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replaceCheckoutStep(step);
      });
    }
    final deliveryFailed = checkout.status == CheckoutStatus.failed &&
        checkout.operation == CheckoutOperation.delivery;
    if (step == 'delivery' && cart.shippingOptions.isEmpty && !deliveryFailed) {
      _scheduleDeliveryLoad();
    }
    return CheckoutScaffold(
      body: CheckoutLayout(step: step, checkout: checkout, cart: cart),
    );
  }

  void _scheduleDeliveryLoad() {
    if (_deliveryLoadScheduled) return;
    _deliveryLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await context.readCheckoutViewModel().loadDelivery();
      _deliveryLoadScheduled = false;
    });
  }

  static String _availableStep(
    String requested,
    CheckoutState checkout,
    CartState cart,
  ) {
    if (checkout.shipping.firstName.isEmpty) return 'address';
    if ((requested == 'payment' || requested == 'review') &&
        cart.cart?.cart.shippingMethod == null) {
      return 'delivery';
    }
    if (requested == 'review' && checkout.paymentMethod == null) {
      return 'payment';
    }
    return requested;
  }
}
