import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Minimal top bar used by Medusa route-focus modals.
final class AdminCustomerCreateHeader extends StatelessWidget {
  /// Creates the close affordance.
  const AdminCustomerCreateHeader({required this.onClose, super.key});

  /// Closes the focus surface when submission is idle.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(children: [
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('esc', style: Theme.of(context).textTheme.labelSmall),
          ),
        ]),
      );
}

/// Sticky customer-create actions matching Medusa's focus footer.
final class AdminCustomerCreateFooter extends StatelessWidget {
  /// Creates cancel and submit actions.
  const AdminCustomerCreateFooter({
    required this.busy,
    required this.onCancel,
    required this.onCreate,
    super.key,
  });

  /// Whether one submission is active.
  final bool busy;

  /// Cancels creation.
  final VoidCallback onCancel;

  /// Submits the form.
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(
            onPressed: busy ? null : onCancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : onCreate,
            child: busy
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ]),
      );
}

/// Optional display-safe failure below the customer fields.
final class AdminCustomerCreateFailure extends StatelessWidget {
  /// Creates the failure region.
  const AdminCustomerCreateFailure({required this.failure, super.key});

  /// Current display-safe failure, when present.
  final Option<String> failure;

  @override
  Widget build(BuildContext context) => switch (failure) {
        Some(:final value) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        None() => const SizedBox.shrink(),
      };
}
