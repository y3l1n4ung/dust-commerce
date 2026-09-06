part of 'admin_product_variant_edit_drawer.dart';

extension on _VariantEditDrawerState {
  List<Widget> _fields(AdminProductDetailState state, bool busy) => [
        _field(
          label: 'Title',
          controller: _title,
          enabled: !busy,
          validator: _requiredTitle,
        ),
        for (final option in widget.product.options) ...[
          const SizedBox(height: 18),
          Text(option.title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: _selections[option.id],
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
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 20),
        Text('Inventory', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 18),
        _field(
          label: 'SKU',
          optional: true,
          controller: _sku,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        const SizedBox(height: 18),
        _field(
          label: 'Barcode',
          optional: true,
          controller: _barcode,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        const SizedBox(height: 22),
        _policy(
          title: 'Manage inventory',
          hint: 'Track stock and prevent sales when inventory runs out.',
          value: _manageInventory,
          busy: busy,
          onChanged: _setManageInventory,
        ),
        const SizedBox(height: 12),
        _policy(
          title: 'Allow backorders',
          hint: 'Keep selling this variant after tracked stock reaches zero.',
          value: _allowBackorder,
          busy: busy,
          onChanged: _setAllowBackorder,
        ),
        if (state.failure case Some(value: final message)) ...[
          const SizedBox(height: 18),
          _failure(message),
        ],
      ];

  Widget _field({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required String? Function(String?) validator,
    bool optional = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
          ]),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            enabled: enabled,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validator,
          ),
        ],
      );

  String? _requiredTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Enter a title';
    return title.length > 255 ? 'Use at most 255 characters' : null;
  }

  String? _optionalIdentifier(String? value) =>
      (value?.length ?? 0) > 255 ? 'Use at most 255 characters' : null;
}
