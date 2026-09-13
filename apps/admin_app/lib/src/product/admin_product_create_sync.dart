part of 'admin_product_create_page.dart';

extension on _AdminProductCreatePageState {
  void _syncHandle() {
    if (_handleEdited) return;
    _handle.text = _slug(_title.text);
  }

  void _syncVariants() {
    final current = {for (final variant in _variants) variant.value: variant};
    final next = <_VariantDraft>[];
    final values = _hasVariants ? _parsedValues() : ['Default option value'];
    for (final value in values) {
      next.add(current.remove(value) ?? _VariantDraft(value));
    }
    for (final removed in current.values) {
      removed.dispose();
    }
    _variants
      ..clear()
      ..addAll(next);
    if (mounted) _rebuild(() {});
  }

  List<String> _parsedValues() {
    final seen = <String>{};
    return [
      for (final part in _optionValues.text.split(','))
        if (part.trim().isNotEmpty && seen.add(part.trim())) part.trim(),
    ];
  }

  void _showInputFailure(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _requiredTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    return text.length > 255 ? 'Use at most 255 characters' : null;
  }

  String? _optional255(String? value) =>
      (value?.length ?? 0) > 255 ? 'Use at most 255 characters' : null;

  String? _optionalHandle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 255) return 'Use at most 255 characters';
    return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(text)
        ? null
        : 'Use lowercase letters, numbers, and hyphens';
  }

  String? _optionValuesValidator(String? value) =>
      _parsedValues().isEmpty ? 'Enter at least one value' : null;

  String _slug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
