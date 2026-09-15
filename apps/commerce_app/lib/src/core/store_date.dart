import 'package:flutter/material.dart';

/// Formats a customer-facing order date with the year Medusa shows.
String formatStoreDate(
  MaterialLocalizations localizations,
  DateTime value,
) {
  final local = value.toLocal();
  return '${localizations.formatMediumDate(local)}, ${local.year}';
}

/// Formats a customer-facing order instant without dropping its year.
String formatStoreDateTime(
  MaterialLocalizations localizations,
  DateTime value,
) {
  final local = value.toLocal();
  return '${formatStoreDate(localizations, local)}, '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
