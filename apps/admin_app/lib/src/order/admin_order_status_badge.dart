import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:flutter/material.dart';

/// Compact lifecycle badge used by Medusa-shaped order detail sections.
final class AdminOrderLifecycleBadge extends StatelessWidget {
  /// Creates an order lifecycle badge.
  const AdminOrderLifecycleBadge({required this.status, super.key});

  /// Current order lifecycle.
  final AdminOrderStatus status;

  @override
  Widget build(BuildContext context) => _StatusBadge(
        label: switch (status) {
          AdminOrderStatus.pending => 'Pending',
          AdminOrderStatus.completed => 'Completed',
          AdminOrderStatus.cancelled => 'Cancelled',
        },
        color: switch (status) {
          AdminOrderStatus.pending => const Color(0xFFF59E0B),
          AdminOrderStatus.completed => const Color(0xFF22C55E),
          AdminOrderStatus.cancelled => const Color(0xFFEF4444),
        },
      );
}

/// Compact order-level payment badge.
final class AdminOrderPaymentBadge extends StatelessWidget {
  /// Creates an order payment badge.
  const AdminOrderPaymentBadge({required this.status, super.key});

  /// Current order payment lifecycle.
  final AdminOrderPaymentStatus status;

  @override
  Widget build(BuildContext context) => _StatusBadge(
        label: switch (status) {
          AdminOrderPaymentStatus.awaiting => 'Awaiting',
          AdminOrderPaymentStatus.captured => 'Captured',
          AdminOrderPaymentStatus.refunded => 'Refunded',
        },
        color: switch (status) {
          AdminOrderPaymentStatus.awaiting => const Color(0xFFF59E0B),
          AdminOrderPaymentStatus.captured => const Color(0xFF22C55E),
          AdminOrderPaymentStatus.refunded => const Color(0xFF71717A),
        },
      );
}

/// Compact order fulfilment badge.
final class AdminOrderFulfillmentBadge extends StatelessWidget {
  /// Creates an order fulfilment badge.
  const AdminOrderFulfillmentBadge({required this.status, super.key});

  /// Current order fulfilment lifecycle.
  final AdminOrderFulfillmentStatus status;

  @override
  Widget build(BuildContext context) => const _StatusBadge(
        label: 'Not fulfilled',
        color: Color(0xFF71717A),
      );
}

final class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}
