import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

part 'admin_product_variant_edit_fields.dart';
part 'admin_product_variant_edit_chrome.dart';

/// Opens the Medusa-shaped right-side variant editor.
Future<bool?> showAdminProductVariantEditDrawer(
  BuildContext context,
  AdminProductDetail product,
  AdminProductVariant variant,
) =>
    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close variant editor',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => Align(
        alignment: Alignment.centerRight,
        child: _VariantEditDrawer(product: product, variant: variant),
      ),
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );

final class _VariantEditDrawer extends StatefulWidget {
  const _VariantEditDrawer({required this.product, required this.variant});

  final AdminProductDetail product;
  final AdminProductVariant variant;

  @override
  State<_VariantEditDrawer> createState() => _VariantEditDrawerState();
}

final class _VariantEditDrawerState extends State<_VariantEditDrawer> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final Map<String, String> _selections;
  late bool _manageInventory;
  late bool _allowBackorder;

  @override
  void initState() {
    super.initState();
    final variant = widget.variant;
    _title = TextEditingController(text: variant.title);
    _sku = TextEditingController(text: variant.sku ?? '');
    _barcode = TextEditingController(text: variant.barcode ?? '');
    _selections = {...variant.optionValues};
    _manageInventory = variant.manageInventory;
    _allowBackorder = variant.allowBackorder;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readAdminProductDetailViewModel().clearFailure();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _sku.dispose();
    _barcode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductDetailViewModel().value;
    final busy = state.isSaving;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 16,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width.clamp(0, 520).toDouble(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(busy),
              Expanded(
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    children: _fields(state, busy),
                  ),
                ),
              ),
              _footer(busy),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final saved = await context.readAdminProductDetailViewModel().updateVariant(
          widget.product.id,
          widget.variant.id,
          AdminUpdateProductVariant(
            title: _title.text.trim(),
            sku: _sku.text,
            barcode: _barcode.text,
            manageInventory: _manageInventory,
            allowBackorder: _allowBackorder,
            optionValues: _selections,
          ),
        );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  void _setManageInventory(bool value) => setState(() {
        _manageInventory = value;
      });

  void _setAllowBackorder(bool value) => setState(() {
        _allowBackorder = value;
      });
}
