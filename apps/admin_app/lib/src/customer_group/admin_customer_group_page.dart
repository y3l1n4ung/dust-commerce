import 'package:admin_app/src/customer_group/admin_customer_group_pagination.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_table_body.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_toolbar.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_view_model.dart';
import 'package:flutter/material.dart';

/// Medusa-shaped customer-group list backed by the protected Admin API.
final class AdminCustomerGroupPage extends StatelessWidget {
  /// Creates the customer-group list route.
  const AdminCustomerGroupPage({required this.searchFocus, super.key});

  /// Focus target shared with the sidebar search action.
  final FocusNode searchFocus;

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminCustomerGroupViewModel().value;
    return SingleChildScrollView(
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const _AdminCustomerGroupHeader(),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              AdminCustomerGroupToolbar(
                state: state,
                searchFocus: searchFocus,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              AdminCustomerGroupTableBody(
                state: state,
                onRetry: context.readAdminCustomerGroupViewModel().load,
              ),
              AdminCustomerGroupPagination(state: state),
            ]),
          ),
        ),
      ),
    );
  }
}

final class _AdminCustomerGroupHeader extends StatelessWidget {
  const _AdminCustomerGroupHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Customer Groups',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      );
}
