import 'package:flutter/material.dart';

/// Date filters exposed by Medusa's customer-group list source.
enum AdminCustomerGroupFilterKind {
  /// Database-owned creation instant.
  createdAt,

  /// Database-owned last-update instant.
  updatedAt,
}

/// Source-shaped Add filter menu for customer groups.
final class AdminCustomerGroupFilterMenu extends StatelessWidget {
  /// Creates the customer-group filter menu.
  const AdminCustomerGroupFilterMenu({required this.onSelected, super.key});

  /// Opens the selected date-range editor.
  final ValueChanged<AdminCustomerGroupFilterKind> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton(
        tooltip: 'Add filter',
        onSelected: onSelected,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: AdminCustomerGroupFilterKind.createdAt,
            child: Text('Created'),
          ),
          PopupMenuItem(
            value: AdminCustomerGroupFilterKind.updatedAt,
            child: Text('Updated'),
          ),
        ],
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, size: 16),
            SizedBox(width: 4),
            Text('Add filter'),
          ]),
        ),
      );
}
