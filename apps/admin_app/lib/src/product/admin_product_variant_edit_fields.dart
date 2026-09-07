part of 'admin_product_variant_edit_drawer.dart';

extension on _VariantEditDrawerState {
  List<Widget> _fields(AdminProductDetailState state, bool busy) => [
        _field(
          label: 'Title',
          controller: _values.title,
          enabled: !busy,
          validator: _requiredTitle,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Material',
          optional: true,
          controller: _values.material,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        for (final option in widget.product.options) ...[
          const SizedBox(height: 16),
          _optionField(option, busy),
        ],
        const SizedBox(height: 32),
        const Divider(height: 1),
        const SizedBox(height: 32),
        ..._inventoryFields(busy),
        const SizedBox(height: 32),
        const Divider(height: 1),
        const SizedBox(height: 32),
        ..._attributeFields(busy),
        if (state.failure case Some(value: final message)) ...[
          const SizedBox(height: 24),
          _failure(message),
        ],
      ];

  Widget _optionField(AdminProductOption option, bool busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(option.title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: _selections[option.id],
            icon: const Icon(Icons.unfold_more_rounded, size: 16),
            items: [
              for (final value in option.values)
                DropdownMenuItem(value: value, child: Text(value)),
            ],
            onChanged: busy
                ? null
                : (value) {
                    if (value != null) _selections[option.id] = value;
                  },
            validator: (value) => value == null ? 'Choose a value' : null,
          ),
        ],
      );

  Widget _field({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required String? Function(String?) validator,
    bool optional = false,
    TextInputType? keyboardType,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            if (optional) ...[
              const SizedBox(width: 5),
              Text(
                '(Optional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ]),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            enabled: enabled,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validator,
            keyboardType: keyboardType,
          ),
        ],
      );

  String? _requiredTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Enter a title';
    return title.length > 255 ? 'Use at most 255 characters' : null;
  }

  String? _optionalIdentifier(String? value) =>
      (value?.trim().length ?? 0) > 255 ? 'Use at most 255 characters' : null;

  String? _optionalNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    if (number == null) return 'Enter a number';
    return number < 0 ? 'Enter zero or a positive number' : null;
  }
}
