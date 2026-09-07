import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

part 'admin_product_stock_table.dart';

/// Opens Medusa's full-screen product stock focus surface.
Future<bool?> showAdminProductStockPage(
  BuildContext context,
  AdminProductDetail product,
) =>
    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Close stock editor',
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (_, __, ___) => _ProductStockPage(product: product),
    );

final class _ProductStockPage extends StatefulWidget {
  const _ProductStockPage({required this.product});

  final AdminProductDetail product;

  @override
  State<_ProductStockPage> createState() => _ProductStockPageState();
}

final class _ProductStockPageState extends State<_ProductStockPage> {
  final _form = GlobalKey<FormState>();
  late final List<_StockDraft> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = [
      for (final variant in widget.product.variants) _StockDraft(variant)
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readAdminProductDetailViewModel().clearFailure();
    });
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.quantity.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductDetailViewModel().value;
    final busy = state.isSaving;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(children: [
          _header(busy),
          Expanded(child: _body(state, busy)),
          _footer(busy),
        ]),
      ),
    );
  }

  Widget _header(bool busy) => Container(
        height: 56,
        padding: const EdgeInsets.only(left: 24, right: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(children: [
          Text('Edit stock', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            onPressed: busy ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ]),
      );

  Widget _footer(bool busy) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : _save,
            child: busy
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ]),
      );

  void _setManaged(_StockDraft draft, bool value) =>
      setState(() => draft.managed = value);

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final saved =
        await context.readAdminProductDetailViewModel().updateProductStock(
            widget.product.id,
            AdminUpdateProductStock(
              variants: [for (final draft in _drafts) draft.request],
            ));
    if (saved && mounted) Navigator.of(context).pop(true);
  }
}

final class _StockDraft {
  _StockDraft(this.variant)
      : managed = variant.manageInventory,
        quantity = TextEditingController(
          text: variant.inventoryQuantity.toString(),
        );

  bool managed;
  final TextEditingController quantity;
  final AdminProductVariant variant;

  AdminUpdateVariantStock get request => AdminUpdateVariantStock(
        id: variant.id,
        inventoryQuantity: int.parse(quantity.text),
        manageInventory: managed,
      );
}
