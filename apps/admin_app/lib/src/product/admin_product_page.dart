import 'package:admin_app/src/product/admin_product_delete.dart';
import 'package:admin_app/src/product/admin_product_state.dart';
import 'package:admin_app/src/product/admin_product_pagination.dart';
import 'package:admin_app/src/product/admin_product_table.dart';
import 'package:admin_app/src/product/admin_product_view_model.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Medusa-shaped product route backed by the authenticated admin API.
final class AdminProductPage extends StatefulWidget {
  /// Creates the product route.
  const AdminProductPage({
    required this.searchFocus,
    required this.onOpenProduct,
    required this.onCreateProduct,
    super.key,
  });

  /// Opens the authenticated product creation focus surface.
  final VoidCallback onCreateProduct;

  /// Focus target shared with the sidebar search action.
  final FocusNode searchFocus;

  /// Opens one product detail from the result table.
  final ValueChanged<String> onOpenProduct;

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

final class _AdminProductPageState extends State<AdminProductPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductViewModel().value;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 1,
            shadowColor: const Color(0x16000000),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _Header(
                  onUnavailable: () => _unavailable(context),
                  onCreate: widget.onCreateProduct,
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _Toolbar(
                  controller: _query,
                  focusNode: widget.searchFocus,
                  onUnavailable: () => _unavailable(context),
                  onSearch: () =>
                      context.readAdminProductViewModel().search(_query.text),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                Expanded(child: _body(context, state)),
                AdminProductPagination(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AdminProductState state) {
    if (state.status == AdminProductStatus.loading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (state.failure case Some(value: final message)
        when state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: context.readAdminProductViewModel().load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.products.isEmpty) {
      return const Center(child: Text('No products found'));
    }
    return Stack(
      children: [
        AdminProductTable(
          products: state.products,
          onOpen: widget.onOpenProduct,
          onDelete: (product) => deleteAdminProductSummary(context, product),
        ),
        if (state.status == AdminProductStatus.loading)
          const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }

  void _unavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('This action needs the next Admin API slice.')),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.onUnavailable, required this.onCreate});

  final VoidCallback onCreate;
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Text('Products', style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            OutlinedButton(
              onPressed: onUnavailable,
              child: const Text('Export'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onUnavailable,
              child: const Text('Import'),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: onCreate, child: const Text('Create')),
          ],
        ),
      );
}

final class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.onUnavailable,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: onUnavailable,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add filter'),
            ),
            const Spacer(),
            SizedBox(
              width: 196,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) => onSearch(),
                decoration: const InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: Icon(Icons.search_rounded, size: 17),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Sort products',
              onPressed: onUnavailable,
              icon: const Icon(Icons.sort_rounded, size: 18),
            ),
          ],
        ),
      );
}
