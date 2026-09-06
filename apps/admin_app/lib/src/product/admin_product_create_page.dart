import 'package:admin_app/src/product/admin_product_create_state.dart';
import 'package:admin_app/src/product/admin_product_create_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dio/dio.dart';
import 'package:dust_dart/fp.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

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

  Widget _mediaSection(AdminProductCreateState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Media', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 5),
              Text(
                'Optional',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          InkWell(
            onTap: state.isBusy || _media.length == 10 ? null : _pickMedia,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 104,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.status == AdminProductCreateStatus.uploading)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.file_upload_outlined, size: 18),
                  const SizedBox(height: 7),
                  Text(
                    state.status == AdminProductCreateStatus.uploading
                        ? 'Uploading images'
                        : 'Upload images',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'JPEG, PNG, GIF, or WebP. Up to 5 MB each.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (_media.isNotEmpty) ...[
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _media.length,
              onReorderItem: _reorderMedia,
              itemBuilder: (context, index) => _MediaRow(
                key: ValueKey(_media[index].file.id),
                index: index,
                draft: _media[index],
                busy: state.isBusy || _discarding,
                onThumbnail: () => _makeThumbnail(index),
                onDelete: () => _removeMedia(index),
              ),
            ),
          ],
        ],
      );

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

  Future<void> _pickMedia() async {
    final selected = await openFiles(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        ),
      ],
    );
    if (!mounted || selected.isEmpty) return;
    final remaining = 10 - _media.length;
    if (selected.length > remaining) {
      _showInputFailure('A product can have at most 10 images.');
      return;
    }
    final files = <MultipartFile>[];
    for (final file in selected) {
      final length = await file.length();
      if (length == 0 || length > 5 * 1024 * 1024) {
        _showInputFailure('Each image must be between 1 byte and 5 MB.');
        return;
      }
      files.add(MultipartFile.fromBytes(
        await file.readAsBytes(),
        filename: file.name,
      ));
    }
    if (!mounted) return;
    final uploaded =
        await context.readAdminProductCreateViewModel().uploadMedia(files);
    if (!mounted) return;
    if (uploaded case Some(:final value)) {
      setState(() {
        for (final file in value) {
          _media.add(_UploadedMediaDraft(
            file,
            isThumbnail: _media.isEmpty,
          ));
        }
      });
    }
  }

  void _reorderMedia(int oldIndex, int newIndex) {
    setState(() {
      final item = _media.removeAt(oldIndex);
      _media.insert(newIndex, item);
    });
  }

  void _makeThumbnail(int index) => setState(() {
        for (var item = 0; item < _media.length; item++) {
          _media[item].isThumbnail = item == index;
        }
      });

  Future<void> _removeMedia(int index) async {
    final item = _media[index];
    final deleted = await context
        .readAdminProductCreateViewModel()
        .discardUpload(item.file.id);
    if (!mounted || !deleted) return;
    setState(() {
      final wasThumbnail = _media.removeAt(index).isThumbnail;
      if (wasThumbnail && _media.isNotEmpty) {
        _media.first.isThumbnail = true;
      }
    });
  }

  Future<void> _cancel() async {
    if (_discarding) return;
    setState(() => _discarding = true);
    for (final item in List<_UploadedMediaDraft>.of(_media)) {
      final deleted = await context
          .readAdminProductCreateViewModel()
          .discardUpload(item.file.id);
      if (!mounted) return;
      if (!deleted) {
        setState(() => _discarding = false);
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

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

final class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.index,
    required this.draft,
    required this.busy,
    required this.onThumbnail,
    required this.onDelete,
    super.key,
  });

  final bool busy;
  final _UploadedMediaDraft draft;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onThumbnail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                enabled: !busy,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 34,
                  height: 42,
                  child: Image.network(
                    draft.file.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: const Icon(Icons.broken_image_outlined, size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.file.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (draft.isThumbnail) ...[
                          const Icon(Icons.photo_size_select_actual_outlined,
                              size: 13),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _fileSize(draft.file.size),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_MediaAction>(
                enabled: !busy,
                tooltip: 'Image actions',
                onSelected: (action) {
                  if (action == _MediaAction.thumbnail) onThumbnail();
                  if (action == _MediaAction.delete) onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _MediaAction.thumbnail,
                    child: Text('Make thumbnail'),
                  ),
                  PopupMenuItem(
                    value: _MediaAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Remove image',
                onPressed: busy ? null : onDelete,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
        ),
      );

  static String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum _MediaAction { thumbnail, delete }

final class _UploadedMediaDraft {
  _UploadedMediaDraft(this.file, {required this.isThumbnail});

  final AdminUploadedFile file;
  bool isThumbnail;
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
