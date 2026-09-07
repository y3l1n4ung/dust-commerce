part of 'admin_sidebar.dart';

final class _SubNav extends StatelessWidget {
  const _SubNav({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
        color: selected
            ? Theme.of(context).colorScheme.surface
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: selected
              ? BorderSide(color: Theme.of(context).dividerColor)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(
            height: 28,
            child: Padding(
              padding: const EdgeInsets.only(left: 41),
              child: Align(alignment: Alignment.centerLeft, child: Text(label)),
            ),
          ),
        ),
      );
}
