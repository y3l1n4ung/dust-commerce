import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Opens the Medusa-shaped right-side general product editor.
Future<bool?> showAdminProductEditDrawer(
  BuildContext context,
  AdminProductDetail product,
) =>
    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close product editor',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => Align(
        alignment: Alignment.centerRight,
        child: _AdminProductEditDrawer(product: product),
      ),
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

final class _AdminProductEditDrawer extends StatefulWidget {
  const _AdminProductEditDrawer({required this.product});

  final AdminProductDetail product;

  @override
  State<_AdminProductEditDrawer> createState() =>
      _AdminProductEditDrawerState();
}

final class _AdminProductEditDrawerState
    extends State<_AdminProductEditDrawer> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _handle;
  late final TextEditingController _subtitle;
  late final TextEditingController _material;
  late final TextEditingController _description;
  late AdminProductLifecycle _status;
  late bool _discountable;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _title = TextEditingController(text: product.title);
    _handle = TextEditingController(text: product.handle);
    _subtitle = TextEditingController(text: product.subtitle ?? '');
    _material = TextEditingController(text: product.material ?? '');
    _description = TextEditingController(text: product.description ?? '');
    _status = product.status;
    _discountable = product.discountable;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readAdminProductDetailViewModel().clearFailure();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _handle.dispose();
    _subtitle.dispose();
    _material.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductDetailViewModel().value;
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
              _Header(onClose: state.isSaving ? null : _close),
              Expanded(
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    children: [
                      _label(context, 'Status'),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<AdminProductLifecycle>(
                        initialValue: _status,
                        items: AdminProductLifecycle.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(_titleCase(status.name)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: state.isSaving
                            ? null
                            : (status) {
                                if (status != null) _status = status;
                              },
                      ),
                      const SizedBox(height: 18),
                      _field(
                        context,
                        label: 'Title',
                        controller: _title,
                        enabled: !state.isSaving,
                        validator: _requiredTitle,
                      ),
                      const SizedBox(height: 18),
                      _field(
                        context,
                        label: 'Subtitle',
                        optional: true,
                        controller: _subtitle,
                        enabled: !state.isSaving,
                        validator: (value) => (value?.length ?? 0) > 255
                            ? 'Use at most 255 characters'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _field(
                        context,
                        label: 'Handle',
                        controller: _handle,
                        enabled: !state.isSaving,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 2),
                          child: Text('/'),
                        ),
                        validator: _validHandle,
                      ),
                      const SizedBox(height: 18),
                      _field(
                        context,
                        label: 'Material',
                        optional: true,
                        controller: _material,
                        enabled: !state.isSaving,
                        validator: (value) => (value?.length ?? 0) > 255
                            ? 'Use at most 255 characters'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _field(
                        context,
                        label: 'Description',
                        optional: true,
                        controller: _description,
                        enabled: !state.isSaving,
                        maxLines: 6,
                        validator: (value) => (value?.length ?? 0) > 20000
                            ? 'Use at most 20000 characters'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      _DiscountableBox(
                        value: _discountable,
                        onChanged: state.isSaving
                            ? null
                            : (value) => setState(() {
                                  _discountable = value;
                                }),
                      ),
                      if (state.failure case Some(value: final message)) ...[
                        const SizedBox(height: 18),
                        _FailureBanner(message: message),
                      ],
                    ],
                  ),
                ),
              ),
              _Footer(
                saving: state.isSaving,
                onCancel: state.isSaving ? null : _close,
                onSave: state.isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required String? Function(String?) validator,
    bool optional = false,
    int maxLines = 1,
    Widget? prefix,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, label, optional: optional),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(prefixIcon: prefix),
            validator: validator,
          ),
        ],
      );

  Widget _label(BuildContext context, String text, {bool optional = false}) =>
      Row(
        children: [
          Text(text, style: Theme.of(context).textTheme.labelLarge),
          if (optional) ...[
            const SizedBox(width: 5),
            Text(
              'Optional',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      );

  String? _requiredTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Enter a title';
    return title.length > 255 ? 'Use at most 255 characters' : null;
  }

  String? _validHandle(String? value) {
    final handle = value?.trim() ?? '';
    if (handle.isEmpty) return 'Enter a handle';
    if (handle.length > 255) return 'Use at most 255 characters';
    return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(handle)
        ? null
        : 'Use lowercase letters, numbers, and hyphens';
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final saved = await context.readAdminProductDetailViewModel().update(
          widget.product.id,
          AdminUpdateProduct(
            status: _status,
            title: _title.text.trim(),
            handle: _handle.text.trim(),
            subtitle: _subtitle.text,
            material: _material.text,
            description: _description.text,
            discountable: _discountable,
          ),
        );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  void _close() => Navigator.of(context).pop(false);

  String _titleCase(String input) =>
      '${input[0].toUpperCase()}${input.substring(1)}';
}

final class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        padding: const EdgeInsets.only(left: 24, right: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Edit product',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      );
}

final class _Footer extends StatelessWidget {
  const _Footer({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSave,
              child: saving
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      );
}

final class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          message,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      );
}

final class _DiscountableBox extends StatelessWidget {
  const _DiscountableBox({required this.value, required this.onChanged});

  final ValueChanged<bool>? onChanged;
  final bool value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 0.8,
                alignment: Alignment.topLeft,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discountable',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Allow promotions to reduce this product price.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
