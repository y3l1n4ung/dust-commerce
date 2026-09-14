import 'package:flutter/material.dart';

/// Customer list heading shaped after Medusa's source container header.
final class AdminCustomerPageHeader extends StatelessWidget {
  /// Creates the heading and honest unavailable create action.
  const AdminCustomerPageHeader({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(children: [
          Text('Customers', style: Theme.of(context).textTheme.headlineSmall),
          const Spacer(),
          const Tooltip(
            message: 'Customer creation is not available yet',
            child: OutlinedButton(onPressed: null, child: Text('Create')),
          ),
        ]),
      );
}
