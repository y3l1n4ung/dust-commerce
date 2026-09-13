import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Medusa-shaped order help block backed by a real return capability.
final class OrderReturnSection extends StatefulWidget {
  /// Creates return help for the immutable [order].
  const OrderReturnSection({required this.order, super.key});

  /// Customer-owned order currently shown by the guarded detail route.
  final Order order;

  @override
  State<OrderReturnSection> createState() => _OrderReturnSectionState();
}

final class _OrderReturnSectionState extends State<OrderReturnSection> {
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(OrderReturnSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) _prepare();
  }

  void _prepare() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.readOrderReturnViewModel().prepare(widget.order);
        }
      });

  @override
  Widget build(BuildContext context) {
    final eligible = widget.order.status == OrderStatus.completed &&
        widget.order.paymentStatus == PaymentStatus.captured;
    if (!eligible) return const SizedBox.shrink();
    final state = context.watchOrderReturnViewModel().value;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'shop_checkout_need_help',
            defaultText: 'Need help?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (!state.expanded)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: context.readOrderReturnViewModel().open,
              child: const TranslatedText(
                'shop_account_returns_exchanges',
                defaultText: 'Returns & Exchanges',
              ),
            )
          else
            OrderReturnForm(order: widget.order, state: state),
        ],
      ),
    );
  }
}
