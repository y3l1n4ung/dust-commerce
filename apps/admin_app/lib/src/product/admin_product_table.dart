import 'package:admin_app/src/product/admin_product_actions.dart';
import 'package:admin_app/src/product/admin_product_sales_channel_cell.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:flutter/material.dart';

/// Desktop-first product table with horizontal safety on narrow viewports.
final class AdminProductTable extends StatelessWidget {
  /// Creates the allowlisted merchant product table.
  const AdminProductTable({
    required this.products,
    required this.onOpen,
    this.onDelete,
    super.key,
  });

  /// Confirms and retires one product where the host route supports mutation.
  final ValueChanged<AdminProduct>? onDelete;

  /// Rows returned by the explicit admin product contract.
  final List<AdminProduct> products;

  /// Opens the complete detail for one product id.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 920 ? 920 : constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _ProductHeader(),
                for (final product in products)
                  _ProductRow(
                    product: product,
                    onOpen: onOpen,
                    onDelete: onDelete,
                  ),
              ],
            ),
          ),
        ),
      );
}

final class _ProductHeader extends StatelessWidget {
  const _ProductHeader();

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: const Row(
          children: [
            Expanded(child: Text('Product')),
            Expanded(child: Text('Collection')),
            Expanded(child: Text('Sales Channels')),
            Expanded(child: Text('Variants')),
            Expanded(child: Text('Status')),
            SizedBox(width: 32),
          ],
        ),
      );
}

final class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onOpen,
    required this.onDelete,
  });

  final ValueChanged<AdminProduct>? onDelete;
  final ValueChanged<String> onOpen;
  final AdminProduct product;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onOpen(product.id),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _Thumbnail(url: product.thumbnail),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(product.title,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _muted(context, product.collectionTitle)),
                Expanded(
                  child: AdminProductSalesChannelCell(
                    channels: product.salesChannels,
                  ),
                ),
                Expanded(child: Text('${product.variantCount}')),
                Expanded(child: _Status(value: product.status)),
                SizedBox(width: 32, child: _actions()),
              ],
            ),
          ),
        ),
      );

  Widget _actions() {
    final delete = onDelete;
    return delete == null
        ? IconButton(
            tooltip: 'Open product',
            onPressed: () => onOpen(product.id),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_horiz_rounded, size: 17),
          )
        : AdminProductActions(
            iconSize: 17,
            onEdit: () => onOpen(product.id),
            onDelete: () => delete(product),
          );
  }

  Widget _muted(BuildContext context, String value) => Text(
        value.isEmpty ? '—' : value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

final class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 26,
          height: 26,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: url.isEmpty
              ? const Icon(Icons.image_outlined, size: 16)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  // Medusa's seed CDN omits CORS headers; HTML rendering keeps
                  // the source image usable on web without proxying secrets.
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_outlined, size: 16),
                ),
        ),
      );
}

final class _Status extends StatelessWidget {
  const _Status({required this.value});

  final AdminProductLifecycle value;

  @override
  Widget build(BuildContext context) {
    final active = value == AdminProductLifecycle.published;
    final color = active ? const Color(0xFF22C55E) : const Color(0xFFA1A1AA);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(child: Text(_titleCase(value.name))),
      ],
    );
  }

  String _titleCase(String input) => input.isEmpty
      ? 'Unknown'
      : '${input[0].toUpperCase()}${input.substring(1).toLowerCase()}';
}
