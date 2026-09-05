import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Source promotion disclosure, input, applied badge, and removal action.
class PromotionCode extends StatefulWidget {
  /// Creates the promotion control.
  const PromotionCode({required this.cart, required this.state, super.key});

  /// Current server cart.
  final Cart cart;

  /// Current mutation state.
  final CartState state;

  @override
  State<PromotionCode> createState() => _PromotionCodeState();
}

class _PromotionCodeState extends State<PromotionCode> {
  final _controller = TextEditingController();
  var _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.state.status == CartStatus.loading;
    final failed = widget.state.status == CartStatus.failed &&
        widget.state.operation == CartOperation.promotion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: busy ? null : () => setState(() => _open = !_open),
            style: TextButton.styleFrom(
              foregroundColor: StoreColors.interactive,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const TranslatedText(
              'shop_cart_add_promotion_codes',
              defaultText: 'Add Promotion Code(s)',
            ),
          ),
        ),
        if (_open) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !busy,
                  decoration: InputDecoration(
                    hintText: context.tr(
                      'shop_cart_promotion_code',
                      defaultText: 'Promotion code',
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _apply(context),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: busy ? null : () => _apply(context),
                child: const TranslatedText(
                  'shop_cart_apply',
                  defaultText: 'Apply',
                ),
              ),
            ],
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.state.message ??
                    context.tr(
                      'shop_cart_promotion_failed',
                      defaultText: 'Could not apply this code.',
                    ),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 20),
        ],
        if (widget.cart.promotionCode case final code?) ...[
          const TranslatedText(
            'shop_cart_promotions_applied',
            defaultText: 'Promotion(s) applied:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: StoreColors.subtleHover,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(code, style: const TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              IconButton(
                onPressed:
                    busy ? null : context.readCartViewModel().removePromotion,
                icon: const Icon(Icons.delete_outline, size: 16),
                tooltip: context.tr(
                  'shop_cart_remove_promotion',
                  defaultText: 'Remove promotion',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _apply(BuildContext context) async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    final applied = await context.readCartViewModel().applyPromotion(code);
    if (applied && mounted) {
      _controller.clear();
      setState(() => _open = false);
    }
  }
}
