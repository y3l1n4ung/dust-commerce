import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

part 'admin_product_variant_edit_fields.dart';
part 'admin_product_variant_edit_inventory.dart';
part 'admin_product_variant_edit_attributes.dart';
part 'admin_product_variant_edit_chrome.dart';
part 'admin_product_variant_edit_countries.dart';
part 'admin_product_variant_edit_values.dart';

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
      pageBuilder: (context, _, __) => Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerRight,
          child: _VariantEditDrawer(product: product, variant: variant),
        ),
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
  final _scroll = ScrollController();
  late final _VariantEditValues _values;
  late final Map<String, String> _selections;
  late bool _manageInventory;
  late bool _allowBackorder;
  late String? _originCountry;

  @override
  void initState() {
    super.initState();
    final variant = widget.variant;
    _values = _VariantEditValues(variant);
    _selections = {...variant.optionValues};
    _manageInventory = variant.manageInventory;
    _allowBackorder = variant.allowBackorder;
    _originCountry = variant.originCountry;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readAdminProductDetailViewModel().clearFailure();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _values.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductDetailViewModel().value;
    final busy = state.isSaving;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          ),
        ),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(0, 560).toDouble(),
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(busy),
              Expanded(
                child: Form(
                  key: _form,
                  child: Scrollbar(
                    controller: _scroll,
                    thumbVisibility: true,
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      children: _fields(state, busy),
                    ),
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
          _values.request(
            manageInventory: _manageInventory,
            allowBackorder: _allowBackorder,
            originCountry: _originCountry,
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

  void _setOriginCountry(String? value) => setState(() {
        _originCountry = value == null || value.isEmpty ? null : value;
        if (_originCountry == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _values.originCountry.clear();
          });
        }
      });

  void _typeOriginCountry(String value) {
    if (value != _variantCountryName(_originCountry)) _originCountry = null;
  }
}
