import 'package:admin_app/src/order/admin_order_export_file.dart';
import 'package:admin_app/src/order/admin_order_export_filters.dart';
import 'package:admin_app/src/order/admin_order_state.dart';
import 'package:admin_app/src/order/admin_order_view_model.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Opens Medusa's right-side order export flow.
Future<bool?> showAdminOrderExportDrawer(
  BuildContext context,
  AdminOrderState state,
) =>
    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close order export',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerRight,
          child: _OrderExportDrawer(state: state),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );

final class _OrderExportDrawer extends StatefulWidget {
  const _OrderExportDrawer({required this.state});

  final AdminOrderState state;

  @override
  State<_OrderExportDrawer> createState() => _OrderExportDrawerState();
}

final class _OrderExportDrawerState extends State<_OrderExportDrawer> {
  bool _busy = false;
  String? _failure;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 16,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(0, 560).toDouble(),
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    AdminOrderExportFilters(state: widget.state),
                    if (_failure case final message?) ...[
                      const SizedBox(height: 16),
                      Text(
                        message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _footer(),
            ],
          ),
        ),
      );

  Widget _header() => Container(
        height: 62,
        padding: const EdgeInsets.only(left: 24, right: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              'Export Orders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ]),
      );

  Widget _footer() => Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _busy ? null : _export,
            child: _busy
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Export'),
          ),
        ]),
      );

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await context.readAdminOrderViewModel().export();
    if (!mounted) return;
    if (result case Err(:final error)) {
      setState(() {
        _busy = false;
        _failure = error;
      });
      return;
    }
    try {
      final saved = await saveAdminOrderExport(
        (result as Ok<String, String>).value,
      );
      if (!mounted) return;
      if (saved) Navigator.pop(context, true);
      if (!saved) setState(() => _busy = false);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = 'Unable to save the export file. Try again.';
        });
      }
    }
  }
}
