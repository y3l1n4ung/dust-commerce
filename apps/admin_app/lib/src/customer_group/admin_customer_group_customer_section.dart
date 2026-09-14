import 'package:admin_app/src/customer_group/admin_customer_group_customer_body.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_customer_controls.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_customer_pagination.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_detail_state.dart';
import 'package:flutter/material.dart';

/// Medusa-shaped searchable customer table for one group.
final class AdminCustomerGroupCustomerSection extends StatefulWidget {
  /// Creates the group-owned customer table.
  const AdminCustomerGroupCustomerSection({
    required this.state,
    required this.onOpenCustomer,
    super.key,
  });

  /// Opens one complete customer route.
  final ValueChanged<String> onOpenCustomer;

  /// Current group customer state.
  final AdminCustomerGroupDetailState state;

  @override
  State<AdminCustomerGroupCustomerSection> createState() =>
      _AdminCustomerGroupCustomerSectionState();
}

final class _AdminCustomerGroupCustomerSectionState
    extends State<AdminCustomerGroupCustomerSection> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.state.customerQuery);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 1,
        shadowColor: const Color(0x12000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: AdminCustomerGroupCustomerControls(
              search: _search,
              state: widget.state,
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          AdminCustomerGroupCustomerBody(
            state: widget.state,
            onOpen: widget.onOpenCustomer,
          ),
          AdminCustomerGroupCustomerPagination(state: widget.state),
        ]),
      );
}
