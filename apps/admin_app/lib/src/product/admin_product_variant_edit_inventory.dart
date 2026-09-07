part of 'admin_product_variant_edit_drawer.dart';

extension on _VariantEditDrawerState {
  List<Widget> _inventoryFields(bool busy) => [
        Text(
          'Stock & Inventory',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        _field(
          label: 'SKU',
          optional: true,
          controller: _values.sku,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'EAN',
          optional: true,
          controller: _values.ean,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'UPC',
          optional: true,
          controller: _values.upc,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Barcode',
          optional: true,
          controller: _values.barcode,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        const SizedBox(height: 28),
        _policy(
          title: 'Manage inventory',
          hint: "When enabled, we'll change the inventory quantity for you "
              'when orders and returns are created.',
          value: _manageInventory,
          busy: busy,
          onChanged: _setManageInventory,
        ),
        const SizedBox(height: 8),
        _policy(
          title: 'Allow backorders',
          hint: 'When enabled, customers can purchase the variant even if '
              "there's no available quantity.",
          value: _allowBackorder,
          busy: busy,
          onChanged: _setAllowBackorder,
        ),
      ];
}
