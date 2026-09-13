import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Opens Medusa's right-side product organization editor.
Future<bool?> showAdminProductOrganizationDrawer(
  BuildContext context,
  AdminProductDetail product,
  List<AdminProductType> productTypes,
) =>
    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close product organization editor',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerRight,
          child: _OrganizationDrawer(
            product: product,
            productTypes: productTypes,
          ),
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

final class _OrganizationDrawer extends StatefulWidget {
  const _OrganizationDrawer({
    required this.product,
    required this.productTypes,
  });

  final AdminProductDetail product;
  final List<AdminProductType> productTypes;

  @override
  State<_OrganizationDrawer> createState() => _OrganizationDrawerState();
}

final class _OrganizationDrawerState extends State<_OrganizationDrawer> {
  late String? _typeId;

  @override
  void initState() {
    super.initState();
    _typeId = widget.product.productTypeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readAdminProductDetailViewModel().clearFailure();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductDetailViewModel().value;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width.clamp(0, 560).toDouble(),
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(state.isSaving),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Product Type',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: _typeId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      for (final type in widget.productTypes)
                        DropdownMenuItem<String?>(
                          value: type.id,
                          child: Text(type.value),
                        ),
                    ],
                    onChanged: state.isSaving
                        ? null
                        : (value) => setState(() => _typeId = value),
                  ),
                  if (state.failure case Some(value: final message)) ...[
                    const SizedBox(height: 16),
                    Text(message,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
            _footer(state.isSaving),
          ],
        ),
      ),
    );
  }

  Widget _header(bool busy) => Container(
        height: 62,
        padding: const EdgeInsets.only(left: 24, right: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Text('Edit Organization',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: busy ? null : Navigator.of(context).pop,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ]),
      );

  Widget _footer(bool busy) => Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(
            onPressed: busy ? null : Navigator.of(context).pop,
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

  Future<void> _save() async {
    final saved =
        await context.readAdminProductDetailViewModel().updateOrganization(
              widget.product.id,
              AdminUpdateProductOrganization(typeId: _typeId),
            );
    if (saved && mounted) Navigator.of(context).pop(true);
  }
}
