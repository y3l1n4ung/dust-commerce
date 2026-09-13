part of 'admin_product_shipping_profile_drawer.dart';

final class _ShippingProfileDrawerBody extends StatelessWidget {
  const _ShippingProfileDrawerBody({
    required this.page,
    required this.selected,
    required this.search,
    required this.failure,
    required this.busy,
    required this.loading,
    required this.onSearchChanged,
    required this.onSelect,
    required this.onLoadMore,
  });

  final bool busy;
  final Option<String> failure;
  final bool loading;
  final VoidCallback onLoadMore;
  final ValueChanged<Option<String>> onSelect;
  final ValueChanged<String> onSearchChanged;
  final AdminShippingProfileList page;
  final TextEditingController search;
  final Option<String> selected;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Shipping Profile',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: search,
            enabled: !busy,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search shipping profiles',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          _ShippingProfileChoice(
            title: 'Unassigned',
            subtitle: 'Clear the shipping profile',
            selected: selected is None<String>,
            busy: busy,
            onTap: () => onSelect(const None()),
          ),
          for (final profile in page.shippingProfiles)
            _ShippingProfileChoice(
              title: profile.name,
              subtitle: profile.type,
              selected: selected == Some(profile.id),
              busy: busy,
              onTap: () => onSelect(Some(profile.id)),
            ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (!loading && page.shippingProfiles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No shipping profiles found')),
            ),
          if (!loading && page.shippingProfiles.length < page.count)
            TextButton(onPressed: onLoadMore, child: const Text('Load more')),
          if (failure case Some(value: final message)) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      );
}

final class _ShippingProfileChoice extends StatelessWidget {
  const _ShippingProfileChoice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback onTap;
  final bool selected;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
        enabled: !busy,
        selected: selected,
        onTap: busy ? null : onTap,
        leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined),
        title: Text(title),
        subtitle: Text(subtitle),
      );
}
