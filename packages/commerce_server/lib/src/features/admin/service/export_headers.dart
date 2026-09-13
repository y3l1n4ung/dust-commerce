/// Builds the Medusa product CSV columns supported by this catalogue schema.
List<String> adminProductExportHeaders({
  required Iterable<String> currencies,
  required int tagCount,
  required int optionCount,
  required int imageCount,
}) =>
    [
      ..._productHeaders,
      for (var index = 1; index <= tagCount; index++) 'Product Tag $index',
      'Product Discountable',
      'Product External Id',
      ..._variantHeaders,
      for (final currency in currencies)
        'Variant Price ${currency.toUpperCase()}',
      for (var index = 1; index <= optionCount; index++) ...[
        'Variant Option $index Name',
        'Variant Option $index Value',
      ],
      for (var index = 1; index <= imageCount; index++)
        'Product Image $index Url',
    ];

const _productHeaders = [
  'Product Id',
  'Product Handle',
  'Product Title',
  'Product Subtitle',
  'Product Description',
  'Product Status',
  'Product Thumbnail',
  'Product Weight',
  'Product Length',
  'Product Width',
  'Product Height',
  'Product HS Code',
  'Product Origin Country',
  'Product MID Code',
  'Product Material',
  'Shipping Profile Id',
  'Product Sales Channel 1',
  'Product Collection Id',
  'Product Type Id',
];

const _variantHeaders = [
  'Variant Id',
  'Variant Title',
  'Variant SKU',
  'Variant Barcode',
  'Variant Allow Backorder',
  'Variant Manage Inventory',
  'Variant Weight',
  'Variant Length',
  'Variant Width',
  'Variant Height',
  'Variant HS Code',
  'Variant Origin Country',
  'Variant MID Code',
  'Variant Material',
];
