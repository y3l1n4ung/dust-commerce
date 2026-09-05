import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';

import 'cart_items.dart';
import 'cart_summary.dart';

/// Responsive CartTemplate grid from the source storefront.
class CartLayout extends StatelessWidget {
  /// Creates a populated cart layout.
  const CartLayout({required this.view, required this.state, super.key});

  /// Server cart and authoritative totals.
  final CartView view;

  /// Mutation progress visible to line controls.
  final CartState state;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 72),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = MediaQuery.sizeOf(context).width >= 1024;
                  final items = CartItems(view: view, state: state);
                  final summary = CartSummary(view: view, state: state);
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [items, const SizedBox(height: 48), summary],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: items),
                      const SizedBox(width: 160),
                      SizedBox(width: 360, child: summary),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
}
