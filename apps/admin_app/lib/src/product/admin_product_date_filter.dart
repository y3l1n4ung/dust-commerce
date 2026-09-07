part of 'admin_product_filter_bar.dart';

final class _DateFilterChip extends StatelessWidget {
  const _DateFilterChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final ValueChanged<AdminDateFilter> onChanged;
  final AdminDateFilter value;

  @override
  Widget build(BuildContext context) => _FilterChipMenu(
        label: '$label: ${_dateLabel(value)}',
        menuChildren: _dateMenuItems(context, onChanged, value: value),
        onClear: () => onChanged(const AdminDateFilter()),
      );
}

List<Widget> _dateMenuItems(
  BuildContext context,
  ValueChanged<AdminDateFilter> onChanged, {
  AdminDateFilter value = const AdminDateFilter(),
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    _dateItem('Today', today, onChanged),
    _dateItem(
        'Last 7 days', today.subtract(const Duration(days: 7)), onChanged),
    _dateItem(
        'Last 30 days', today.subtract(const Duration(days: 30)), onChanged),
    _dateItem(
        'Last 90 days', today.subtract(const Duration(days: 90)), onChanged),
    _dateItem('Last 12 months', _monthsAgo(today, 12), onChanged),
    MenuItemButton(
      onPressed: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(now.year + 1, 12, 31),
          initialDateRange: _initialRange(value, today),
        );
        if (range == null || !context.mounted) return;
        onChanged(AdminDateFilter(
          greaterThanOrEqual: Some(range.start),
          lessThanOrEqual: Some(_endOfDay(range.end)),
        ));
      },
      child: const Text('Custom range'),
    ),
  ];
}

MenuItemButton _dateItem(
  String label,
  DateTime start,
  ValueChanged<AdminDateFilter> onChanged,
) =>
    MenuItemButton(
      onPressed: () => onChanged(AdminDateFilter(
        greaterThanOrEqual: Some(start),
      )),
      child: Text(label),
    );

DateTimeRange _initialRange(AdminDateFilter value, DateTime fallback) {
  final start = switch (value.greaterThanOrEqual) {
    Some(value: final date) => date.toLocal(),
    None() => fallback,
  };
  final end = switch (value.lessThanOrEqual) {
    Some(value: final date) => date.toLocal(),
    None() => fallback,
  };
  return DateTimeRange(start: start, end: end);
}

DateTime _endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999, 999);

DateTime _monthsAgo(DateTime value, int months) {
  final index = value.year * 12 + value.month - 1 - months;
  final year = index ~/ 12;
  final month = index % 12 + 1;
  final day = min(value.day, DateTime(year, month + 1, 0).day);
  return DateTime(year, month, day);
}

String _dateLabel(AdminDateFilter value) {
  final format = DateFormat.MMMd();
  final start = switch (value.greaterThanOrEqual) {
    Some(value: final date) => format.format(date.toLocal()),
    None() => '',
  };
  final end = switch (value.lessThanOrEqual) {
    Some(value: final date) => format.format(date.toLocal()),
    None() => '',
  };
  if (start.isNotEmpty && end.isNotEmpty) return '$start – $end';
  if (start.isNotEmpty) return 'since $start';
  return 'before $end';
}
