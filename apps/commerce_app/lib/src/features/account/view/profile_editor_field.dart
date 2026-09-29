import 'package:commerce_app/commerce_app.dart';
import 'package:flutter/material.dart';

/// One required input shared by Medusa-shaped profile editors.
final class ProfileEditorField extends StatelessWidget {
  /// Creates a profile editor input.
  const ProfileEditorField({
    required this.controller,
    required this.label,
    required this.validator,
    this.autofillHints,
    this.obscureText = false,
    this.width,
    super.key,
  });

  /// Platform autofill values accepted by this input.
  final Iterable<String>? autofillHints;

  /// Text controller owned by the profile editor.
  final TextEditingController controller;

  /// Human-readable field label.
  final String label;

  /// Whether the field should hide its value.
  final bool obscureText;

  /// Validation owned by the profile operation.
  final String? Function(String?) validator;

  /// Optional width used by the wrapping password grid.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: autofillHints,
      validator: validator,
      decoration: InputDecoration(
        labelText: '$label *',
        filled: true,
        fillColor: StoreColors.subtle,
        border: const OutlineInputBorder(),
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}
