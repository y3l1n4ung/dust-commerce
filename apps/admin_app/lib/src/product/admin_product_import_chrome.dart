import 'package:admin_app/src/product/admin_product_import_summary.dart';
import 'package:admin_app/src/product/admin_product_import_upload.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

/// Stable drawer chrome around the product-import state and actions.
final class AdminProductImportChrome extends StatelessWidget {
  /// Creates the Medusa-shaped import layout.
  const AdminProductImportChrome({
    required this.file,
    required this.preview,
    required this.failure,
    required this.busy,
    required this.onPick,
    required this.onRemove,
    required this.onDownloadTemplate,
    required this.onImport,
    required this.onClose,
    super.key,
  });

  /// Whether local or server preprocessing is active.
  final bool busy;

  /// Selected CSV file.
  final XFile? file;

  /// Merchant-facing preprocessing failure.
  final String? failure;

  /// Closes the drawer without mutating the catalogue.
  final VoidCallback? onClose;

  /// Downloads the canonical CSV header template.
  final VoidCallback? onDownloadTemplate;

  /// Opens the platform CSV picker.
  final VoidCallback? onPick;

  /// Atomically consumes the staged import after a successful preview.
  final VoidCallback? onImport;

  /// Removes the current local and staged preview.
  final VoidCallback? onRemove;

  /// Server-owned product counts and transaction identifier.
  final AdminProductImportPreview? preview;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 16,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(0, 560).toDouble(),
          height: double.infinity,
          child: Column(children: [
            _header(context),
            Expanded(child: _body(context)),
            _footer(context),
          ]),
        ),
      );

  Widget _body(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AdminProductImportUpload(
            file: file,
            busy: busy,
            onPick: onPick,
            onRemove: onRemove,
          ),
          if (preview case final value?) ...[
            const SizedBox(height: 24),
            AdminProductImportSummaryCard(preview: value),
          ],
          const SizedBox(height: 28),
          Text('Product import template',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Use the template to format products and variants correctly.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onDownloadTemplate,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download template'),
            ),
          ),
          if (failure case final message?) ...[
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      );

  Widget _header(BuildContext context) => Container(
        height: 62,
        padding: const EdgeInsets.only(left: 24, right: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Text('Product Import',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ]),
      );

  Widget _footer(BuildContext context) => Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(onPressed: onClose, child: const Text('Cancel')),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onImport,
            child: busy
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Import'),
          ),
        ]),
      );
}
