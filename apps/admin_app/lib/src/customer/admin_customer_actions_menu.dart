import 'package:flutter/material.dart';

/// Available actions for one merchant-visible customer.
final class AdminCustomerActionsMenu extends StatelessWidget {
  /// Creates the currently supported customer actions.
  const AdminCustomerActionsMenu({required this.onEdit, super.key});

  /// Opens the customer contact editor.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_CustomerAction>(
        tooltip: 'Customer actions',
        icon: const Icon(Icons.more_horiz_rounded, size: 18),
        onSelected: (_) => onEdit(),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _CustomerAction.edit,
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 10),
              Text('Edit'),
            ]),
          ),
        ],
      );
}

enum _CustomerAction { edit }
