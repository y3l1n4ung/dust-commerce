import 'package:admin_app/src/product/admin_product_state.dart';
import 'package:admin_app/src/product/admin_product_view_model.dart';
import 'package:flutter/material.dart';

/// Server-owned product paging controls.
final class AdminProductPagination extends StatelessWidget {
  /// Creates catalogue paging for [state].
  const AdminProductPagination({required this.state, super.key});

  /// Current list bounds and total.
  final AdminProductState state;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${state.offset + 1}-${state.offset + state.products.length} of ${state.count}',
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Previous page',
              onPressed: state.hasPrevious
                  ? context.readAdminProductViewModel().previous
                  : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: state.hasNext
                  ? context.readAdminProductViewModel().next
                  : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
            ),
          ],
        ),
      );
}
