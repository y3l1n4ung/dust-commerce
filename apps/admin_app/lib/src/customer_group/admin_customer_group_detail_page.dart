import 'package:admin_app/src/customer_group/admin_customer_group_detail_layout.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_detail_state.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_detail_view_model.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_edit_drawer.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Protected Medusa-shaped route for one merchant customer group.
final class AdminCustomerGroupDetailPage extends StatefulWidget {
  /// Creates the detail route for [customerGroupId].
  const AdminCustomerGroupDetailPage({
    required this.customerGroupId,
    required this.onBack,
    required this.onOpenCustomer,
    super.key,
  });

  /// Stable customer-group identifier loaded from the Admin API.
  final String customerGroupId;

  /// Returns to the customer-group table.
  final VoidCallback onBack;

  /// Opens one group customer in the existing customer detail route.
  final ValueChanged<String> onOpenCustomer;

  @override
  State<AdminCustomerGroupDetailPage> createState() =>
      _AdminCustomerGroupDetailPageState();
}

final class _AdminCustomerGroupDetailPageState
    extends State<AdminCustomerGroupDetailPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AdminCustomerGroupDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerGroupId != widget.customerGroupId) _load();
  }

  void _load() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context
              .readAdminCustomerGroupDetailViewModel()
              .load(widget.customerGroupId);
        }
      });

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminCustomerGroupDetailViewModel().value;
    return switch (state.customerGroup) {
      Some(value: final group) => AdminCustomerGroupDetailLayout(
          customerGroup: group,
          state: state,
          onEdit: () => _edit(group),
          onOpenCustomer: widget.onOpenCustomer,
        ),
      None() when state.status == AdminCustomerGroupDetailStatus.loading =>
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      None() => _AdminCustomerGroupDetailFailure(
          message: state.failure.match(
            some: (value) => value,
            none: () => 'Unable to load this customer group.',
          ),
          onBack: widget.onBack,
          onRetry: _load,
        ),
    };
  }

  Future<void> _edit(AdminCustomerGroupDetail group) async {
    final updated = await showAdminCustomerGroupEditDrawer(context, group);
    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Customer group ${updated.name} was successfully updated.',
      ),
    ));
    await context.readAdminCustomerGroupDetailViewModel().load(updated.id);
  }
}

final class _AdminCustomerGroupDetailFailure extends StatelessWidget {
  const _AdminCustomerGroupDetailFailure({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            OutlinedButton(
              onPressed: onBack,
              child: const Text('Customer Groups'),
            ),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ]),
      );
}
