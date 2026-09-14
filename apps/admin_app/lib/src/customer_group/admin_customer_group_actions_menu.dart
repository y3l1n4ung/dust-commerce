import 'package:flutter/material.dart';

/// Available actions for one merchant-visible customer group.
final class AdminCustomerGroupActionsMenu extends StatelessWidget {
  /// Creates the currently supported group actions.
  const AdminCustomerGroupActionsMenu({
    required this.onEdit,
    super.key,
  });

  /// Opens the customer-group name editor.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_CustomerGroupAction>(
        tooltip: 'Customer group actions',
        icon: const Icon(Icons.more_horiz_rounded, size: 18),
        onSelected: (_) => onEdit(),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _CustomerGroupAction.edit,
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 10),
              Text('Edit'),
            ]),
          ),
        ],
      );
}

enum _CustomerGroupAction { edit }
