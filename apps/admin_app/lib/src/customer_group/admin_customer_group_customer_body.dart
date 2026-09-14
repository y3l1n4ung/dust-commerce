import 'package:admin_app/src/customer/admin_customer_table.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_detail_state.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_detail_view_model.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Loading, failure, empty, and populated group-customer table body.
final class AdminCustomerGroupCustomerBody extends StatelessWidget {
  /// Creates the explicit customer-section body.
  const AdminCustomerGroupCustomerBody({
    required this.state,
    required this.onOpen,
    super.key,
  });

  /// Opens one customer detail route.
  final ValueChanged<String> onOpen;

  /// Current customer section state.
  final AdminCustomerGroupDetailState state;

  @override
  Widget build(BuildContext context) {
    if (state.customersStatus == AdminCustomerGroupCustomersStatus.loading &&
        state.customers.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (state.customerFailure case Some(:final value)
        when state.customers.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: OutlinedButton(
            onPressed:
                context.readAdminCustomerGroupDetailViewModel().loadCustomers,
            child: Text('$value Retry'),
          ),
        ),
      );
    }
    if (state.customers.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("This group doesn't have customers.")),
      );
    }
    return Stack(children: [
      AdminCustomerTable(customers: state.customers, onOpen: onOpen),
      if (state.customersStatus == AdminCustomerGroupCustomersStatus.loading)
        const LinearProgressIndicator(minHeight: 2),
    ]);
  }
}
