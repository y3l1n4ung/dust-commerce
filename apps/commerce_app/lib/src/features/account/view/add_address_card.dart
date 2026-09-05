import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Source-shaped card that opens a new-address dialog.
final class AddAddressCard extends StatelessWidget {
  /// Creates the new-address action.
  const AddAddressCard({required this.onTap, required this.enabled, super.key});

  /// Whether region-backed country options are ready.
  final bool enabled;

  /// Opens the address dialog.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(220),
          padding: const EdgeInsets.all(20),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TranslatedText(
              'shop_account_new_address',
              defaultText: 'New address',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.add, size: 24),
            ),
          ],
        ),
      );
}
