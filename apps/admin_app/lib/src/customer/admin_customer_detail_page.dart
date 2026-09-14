import 'package:admin_app/src/customer/admin_customer_detail_layout.dart';
import 'package:admin_app/src/customer/admin_customer_detail_state.dart';
import 'package:admin_app/src/customer/admin_customer_detail_view_model.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Protected Medusa-shaped route for one merchant customer profile.
final class AdminCustomerDetailPage extends StatefulWidget {
  /// Creates the detail route for [customerId].
  const AdminCustomerDetailPage({
    required this.customerId,
    required this.onBack,
    required this.onOpenOrder,
    super.key,
  });

  /// Stable customer identifier loaded from the Admin API.
  final String customerId;

  /// Returns to the customer table.
  final VoidCallback onBack;

  /// Opens one order from this customer's history.
  final ValueChanged<String> onOpenOrder;

  @override
  State<AdminCustomerDetailPage> createState() =>
      _AdminCustomerDetailPageState();
}

final class _AdminCustomerDetailPageState
    extends State<AdminCustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AdminCustomerDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId) _load();
  }

  void _load() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.readAdminCustomerDetailViewModel().load(widget.customerId);
        }
      });

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminCustomerDetailViewModel().value;
    return switch (state.customer) {
      Some(value: final customer) => AdminCustomerDetailLayout(
          customer: customer,
          state: state,
          onOpenOrder: widget.onOpenOrder,
        ),
      None() when state.status == AdminCustomerDetailStatus.loading =>
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      None() => _AdminCustomerDetailFailure(
          message: switch (state.failure) {
            Some(:final value) => value,
            None() => 'Unable to load this customer.',
          },
          onBack: widget.onBack,
          onRetry: _load,
        ),
    };
  }
}

final class _AdminCustomerDetailFailure extends StatelessWidget {
  const _AdminCustomerDetailFailure({
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
            OutlinedButton(onPressed: onBack, child: const Text('Customers')),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ]),
      );
}
