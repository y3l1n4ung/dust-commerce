import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Public Medusa-compatible order-transfer decision route.
@AppRoute('/order/:id/transfer/:token', name: 'orderTransfer', guards: [])
final class OrderTransferPage extends StatefulWidget {
  /// Creates the neutral decision page from an emailed capability URL.
  const OrderTransferPage({
    required this.id,
    required this.token,
    super.key,
  });

  /// Order identifier named by the transfer link.
  final String id;

  /// Single-use capability passed only to a deliberate decision action.
  final String token;

  @override
  State<OrderTransferPage> createState() => _OrderTransferPageState();
}

final class _OrderTransferPageState extends State<OrderTransferPage> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _resetAfterFrame();
  }

  void _resetAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.readOrderTransferViewModel().reset();
      setState(() => _ready = true);
    });
  }

  @override
  void didUpdateWidget(OrderTransferPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id == widget.id && oldWidget.token == widget.token) return;
    _ready = false;
    _resetAfterFrame();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchOrderTransferViewModel().value;
    return StoreScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Center(
                child: FractionallySizedBox(
                  widthFactor: constraints.maxWidth >= 640 ? 0.4 : 1,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth >= 640 ? 0 : 24,
                      40,
                      constraints.maxWidth >= 640 ? 0 : 24,
                      80,
                    ),
                    child: _ready
                        ? _content(context, state)
                        : const SizedBox(height: 500),
                  ),
                ),
              ),
            ),
            const StoreFooter(),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, OrderTransferState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrderTransferImage(),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'shop_order_transfer_title',
              defaultText: 'Transfer request for order {id}',
              args: {'id': widget.id},
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr(
              'shop_order_transfer_intro',
              defaultText: "You've received a request to transfer ownership "
                  'of your order ({id}). If you agree to this request, you can '
                  'approve the transfer by clicking the button below.',
              args: {'id': widget.id},
            ),
            style: const TextStyle(
              color: StoreColors.foregroundSubtle,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const TranslatedText(
            'shop_order_transfer_responsibility',
            defaultText: 'If you accept, the new owner will take over all '
                'responsibilities and permissions associated with this order.',
            style: TextStyle(
              color: StoreColors.foregroundSubtle,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const TranslatedText(
            'shop_order_transfer_ignore',
            defaultText: 'If you do not recognize this request or wish to '
                'retain ownership, no further action is required.',
            style: TextStyle(
              color: StoreColors.foregroundSubtle,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          OrderTransferActions(
            orderId: widget.id,
            token: widget.token,
            state: state,
          ),
        ],
      );
}
