import 'package:admin_app/src/product/admin_product_create_state.dart';
import 'package:admin_app/src/product/admin_product_create_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dio/dio.dart';
import 'package:dust_dart/fp.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

part 'admin_product_create_media_actions.dart';
part 'admin_product_create_media_view.dart';

/// Opens Medusa's full-screen product creation focus surface.
Future<Option<AdminProductDetail>> showAdminProductCreatePage(
  BuildContext context,
) async {
  final product = await showGeneralDialog<AdminProductDetail>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Create product',
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const AdminProductCreatePage(),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
  return product == null ? const None<AdminProductDetail>() : Some(product);
}

/// Responsive three-step product form backed by the real admin API.
final class AdminProductCreatePage extends StatefulWidget {
  /// Creates the product focus surface.
  const AdminProductCreatePage({super.key});

  @override
  State<AdminProductCreatePage> createState() => _AdminProductCreatePageState();
}

final class _AdminProductCreatePageState extends State<AdminProductCreatePage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _handle = TextEditingController();
  final _description = TextEditingController();
  final _material = TextEditingController();
  final _optionTitle = TextEditingController(text: 'Default option');
  final _optionValues = TextEditingController(text: 'Default option value');
  final _media = <_UploadedMediaDraft>[];
  final _variants = <_VariantDraft>[];

  var _step = 0;
  var _discountable = true;
  var _hasVariants = true;
  var _handleEdited = false;
  var _discarding = false;

  @override
  void initState() {
    super.initState();
    _syncVariants();
    _title.addListener(_syncHandle);
    _optionValues.addListener(_syncVariants);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readAdminProductCreateViewModel().load();
    });
  }

  @override
  void dispose() {
    _title
      ..removeListener(_syncHandle)
      ..dispose();
    _subtitle.dispose();
    _handle.dispose();
    _description.dispose();
    _material.dispose();
    _optionTitle.dispose();
    _optionValues
      ..removeListener(_syncVariants)
      ..dispose();
    for (final variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductCreateViewModel().value;
    final busy = state.isBusy || _discarding;
    return PopScope(
      canPop: !busy && _media.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) _cancel();
      },
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              _CreateHeader(
                step: _step,
                saving: busy,
                onStep: (step) => setState(() => _step = step),
                onClose: busy ? null : () => _cancel(),
              ),
              Expanded(child: _body(state)),
              _CreateFooter(
                step: _step,
                saving: busy,
                onCancel: busy ? null : () => _cancel(),
                onDraft:
                    busy ? null : () => _submit(AdminProductLifecycle.draft),
                onPrimary: busy
                    ? null
                    : () {
                        if (_step < 2) {
                          setState(() => _step++);
                        } else {
                          _submit(AdminProductLifecycle.published);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AdminProductCreateState state) {
    if (state.status == AdminProductCreateStatus.loading ||
        state.status == AdminProductCreateStatus.idle) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (state.status == AdminProductCreateStatus.failed) {
      final message = switch (state.failure) {
        Some(:final value) => value,
        None() => 'Unable to prepare product creation.',
      };
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: context.readAdminProductCreateViewModel().load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    for (final variant in _variants) {
      variant.ensureCurrencies(state.currencyCodes);
    }
    return Form(
      key: _form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              child: switch (_step) {
                0 => _details(state),
                1 => _organize(state),
                _ => _variantEditor(state),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(AdminProductCreateState state) => Column(
        key: const ValueKey('details'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('General', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          LayoutBuilder(builder: (context, constraints) {
            final fields = [
              _field(
                label: 'Title',
                controller: _title,
                validator: _requiredTitle,
              ),
              _field(
                label: 'Subtitle',
                optional: true,
                controller: _subtitle,
                validator: _optional255,
              ),
              _field(
                label: 'Handle',
                optional: true,
                controller: _handle,
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 10, right: 2),
                  child: Text('/'),
                ),
                onChanged: (_) => _handleEdited = true,
                validator: _optionalHandle,
              ),
            ];
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  for (final field in fields) ...[
                    field,
                    const SizedBox(height: 18),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < fields.length; index++) ...[
                  Expanded(child: fields[index]),
                  if (index < fields.length - 1) const SizedBox(width: 16),
                ],
              ],
            );
          }),
          const SizedBox(height: 18),
          _field(
            label: 'Description',
            optional: true,
            controller: _description,
            maxLines: 6,
            validator: (value) => (value?.length ?? 0) > 20000
                ? 'Use at most 20000 characters'
                : null,
          ),
          const SizedBox(height: 24),
          _mediaSection(state),
          const SizedBox(height: 32),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 32),
          Text('Variants', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Add the option and values customers use to choose this product.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Switch(
                  value: _hasVariants,
                  onChanged: (value) {
                    setState(() => _hasVariants = value);
                    _syncVariants();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yes, this is a product with variants',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'When disabled, a default variant is created for you.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_hasVariants) ...[
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, constraints) {
              final option = _field(
                label: 'Option',
                controller: _optionTitle,
                validator: _requiredTitle,
              );
              final values = _field(
                label: 'Values',
                controller: _optionValues,
                helper: 'Separate values with commas',
                validator: _optionValuesValidator,
              );
              if (constraints.maxWidth < 620) {
                return Column(
                  children: [
                    option,
                    const SizedBox(height: 18),
                    values,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: option),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: values),
                ],
              );
            }),
          ],
          _failure(state),
        ],
      );

  Widget _organize(AdminProductCreateState state) => Column(
        key: const ValueKey('organize'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Organize', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          _field(
            label: 'Material',
            optional: true,
            controller: _material,
            validator: _optional255,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Discountable',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Allow promotions to reduce this product price.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _discountable,
                  onChanged: (value) => setState(() => _discountable = value),
                ),
              ],
            ),
          ),
          _failure(state),
        ],
      );

  Widget _variantEditor(AdminProductCreateState state) => Column(
        key: const ValueKey('variants'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Variants', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Set inventory and regional pricing for every sellable variant.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          for (final variant in _variants) ...[
            _VariantCard(
              draft: variant,
              currencies: state.currencyCodes,
            ),
            const SizedBox(height: 12),
          ],
          _failure(state),
        ],
      );

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool optional = false,
    int maxLines = 1,
    Widget? prefix,
    String? helper,
    ValueChanged<String>? onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
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
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(prefixIcon: prefix, helperText: helper),
            validator: validator,
          ),
        ],
      );

  Widget _failure(AdminProductCreateState state) => switch (state.failure) {
        Some(:final value) => Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(value),
            ),
          ),
        None() => const SizedBox.shrink(),
      };

  Future<void> _submit(AdminProductLifecycle status) async {
    context.readAdminProductCreateViewModel().clearFailure();
    final product = _product(status);
    if (product case None()) return;
    final created = await context
        .readAdminProductCreateViewModel()
        .create((product as Some<AdminCreateProduct>).value);
    if (!mounted) return;
    if (created case Some(:final value)) Navigator.of(context).pop(value);
  }

  Option<AdminCreateProduct> _product(AdminProductLifecycle status) {
    final formValid = _form.currentState?.validate() ?? false;
    final optionTitle =
        _hasVariants ? _optionTitle.text.trim() : 'Default option';
    final values = _hasVariants ? _parsedValues() : ['Default option value'];
    final generalValid = _requiredTitle(_title.text) == null &&
        _optional255(_subtitle.text) == null &&
        _optionalHandle(_handle.text) == null &&
        _optional255(_material.text) == null &&
        _description.text.length <= 20000;
    if (!formValid || !generalValid || optionTitle.isEmpty || values.isEmpty) {
      if (!generalValid) setState(() => _step = 0);
      _showInputFailure('Complete the required product details.');
      return const None();
    }
    final currencies =
        context.readAdminProductCreateViewModel().state.currencyCodes;
    final variants = <AdminCreateProductVariant>[];
    for (final draft in _variants) {
      final inventory = int.tryParse(draft.inventory.text.trim());
      if (draft.sku.text.length > 255) {
        setState(() => _step = 2);
        _showInputFailure('Use at most 255 characters for a SKU.');
        return const None();
      }
      final prices = <AdminCreateProductPrice>[];
      for (final currency in currencies) {
        final amount = _minorUnits(draft.prices[currency]!.text);
        if (amount == null) {
          setState(() => _step = 2);
          _showInputFailure(
              'Enter every regional price with at most 2 decimals.');
          return const None();
        }
        prices.add(AdminCreateProductPrice(
          currencyCode: currency,
          amount: amount,
        ));
      }
      if (inventory == null || inventory < 0) {
        setState(() => _step = 2);
        _showInputFailure('Enter a non-negative inventory quantity.');
        return const None();
      }
      variants.add(AdminCreateProductVariant(
        title: draft.value,
        sku: draft.sku.text,
        inventoryQuantity: inventory,
        manageInventory: draft.manageInventory,
        allowBackorder: draft.allowBackorder,
        optionValues: {optionTitle: draft.value},
        prices: prices,
      ));
    }
    return Some(AdminCreateProduct(
      status: status,
      title: _title.text,
      handle: _handle.text,
      subtitle: _subtitle.text,
      material: _material.text,
      description: _description.text,
      discountable: _discountable,
      media: [
        for (final item in _media)
          AdminCreateProductMedia(
            id: item.file.id,
            url: item.file.url,
            isThumbnail: item.isThumbnail,
          ),
      ],
      options: [
        AdminCreateProductOption(title: optionTitle, values: values),
      ],
      variants: variants,
    ));
  }

  void _syncHandle() {
    if (_handleEdited) return;
    _handle.text = _slug(_title.text);
  }

  void _syncVariants() {
    final current = {for (final variant in _variants) variant.value: variant};
    final next = <_VariantDraft>[];
    final values = _hasVariants ? _parsedValues() : ['Default option value'];
    for (final value in values) {
      next.add(current.remove(value) ?? _VariantDraft(value));
    }
    for (final removed in current.values) {
      removed.dispose();
    }
    _variants
      ..clear()
      ..addAll(next);
    if (mounted) setState(() {});
  }

  List<String> _parsedValues() {
    final seen = <String>{};
    return [
      for (final part in _optionValues.text.split(','))
        if (part.trim().isNotEmpty && seen.add(part.trim())) part.trim(),
    ];
  }

  void _showInputFailure(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _rebuild(VoidCallback mutation) => setState(mutation);

  String? _requiredTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    return text.length > 255 ? 'Use at most 255 characters' : null;
  }

  String? _optional255(String? value) =>
      (value?.length ?? 0) > 255 ? 'Use at most 255 characters' : null;

  String? _optionalHandle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 255) return 'Use at most 255 characters';
    return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(text)
        ? null
        : 'Use lowercase letters, numbers, and hyphens';
  }

  String? _optionValuesValidator(String? value) =>
      _parsedValues().isEmpty ? 'Enter at least one value' : null;

  String _slug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  int? _minorUnits(String value) {
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(value.trim());
    if (match == null) return null;
    final whole = int.tryParse(match.group(1)!);
    if (whole == null) return null;
    final decimal = (match.group(2) ?? '').padRight(2, '0');
    return whole * 100 + (int.tryParse(decimal) ?? 0);
  }
}

final class _CreateHeader extends StatelessWidget {
  const _CreateHeader({
    required this.step,
    required this.saving,
    required this.onStep,
    required this.onClose,
  });

  final VoidCallback? onClose;
  final ValueChanged<int> onStep;
  final bool saving;
  final int step;

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'esc',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
            for (var index = 0; index < 3; index++)
              InkWell(
                onTap: saving ? null : () => onStep(index),
                child: Container(
                  height: 56,
                  constraints: const BoxConstraints(minWidth: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < step
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: index <= step
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: index < step
                            ? Icon(
                                Icons.check_rounded,
                                size: 11,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : index == step
                                ? Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  )
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        const ['Details', 'Organize', 'Variants'][index],
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: step == index
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

final class _CreateFooter extends StatelessWidget {
  const _CreateFooter({
    required this.step,
    required this.saving,
    required this.onCancel,
    required this.onDraft,
    required this.onPrimary,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onDraft;
  final VoidCallback? onPrimary;
  final bool saving;
  final int step;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
              onPressed: onDraft,
              child: const Text('Save as draft'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onPrimary,
              child: saving
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(step < 2 ? 'Continue' : 'Publish product'),
            ),
          ],
        ),
      );
}

final class _VariantCard extends StatefulWidget {
  const _VariantCard({required this.draft, required this.currencies});

  final List<String> currencies;
  final _VariantDraft draft;

  @override
  State<_VariantCard> createState() => _VariantCardState();
}

final class _VariantCardState extends State<_VariantCard> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(draft.value, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _compactField('SKU', draft.sku, width: 180),
              _compactField(
                'Inventory',
                draft.inventory,
                width: 120,
                enabled: draft.manageInventory,
              ),
              for (final currency in widget.currencies)
                _compactField(
                  '${currency.toUpperCase()} price',
                  draft.prices[currency]!,
                  width: 140,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Manage inventory'),
                value: draft.manageInventory,
                onChanged: (value) => setState(() {
                  draft.manageInventory = value ?? false;
                }),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Allow backorders'),
                value: draft.allowBackorder,
                onChanged: (value) => setState(() {
                  draft.allowBackorder = value ?? false;
                }),
              ),
            ].map((child) => SizedBox(width: 210, child: child)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _compactField(
    String label,
    TextEditingController controller, {
    required double width,
    bool enabled = true,
  }) =>
      SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            TextField(controller: controller, enabled: enabled),
          ],
        ),
      );
}

final class _VariantDraft {
  _VariantDraft(this.value);

  final String value;
  final sku = TextEditingController();
  final inventory = TextEditingController(text: '0');
  final prices = <String, TextEditingController>{};
  var manageInventory = false;
  var allowBackorder = false;

  void ensureCurrencies(List<String> currencies) {
    for (final currency in currencies) {
      prices.putIfAbsent(currency, TextEditingController.new);
    }
  }

  void dispose() {
    sku.dispose();
    inventory.dispose();
    for (final controller in prices.values) {
      controller.dispose();
    }
  }
}
