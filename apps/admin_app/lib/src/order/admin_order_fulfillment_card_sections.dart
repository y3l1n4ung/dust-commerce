part of 'admin_order_fulfillment_card.dart';

final class _AdminFulfillmentCardHeader extends StatelessWidget {
  const _AdminFulfillmentCardHeader({
    required this.fulfillment,
    required this.index,
  });

  final AdminOrderFulfillment fulfillment;
  final int index;

  @override
  Widget build(BuildContext context) {
    final status = _status(fulfillment);
    return _AdminFulfillmentBorder(
      child: Row(children: [
        Expanded(
          child: Text(
            'Fulfillment #${index + 1}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Tooltip(
          message: DateFormat('dd MMM, yyyy, HH:mm:ss').format(status.date),
          child: Chip(label: Text(status.label)),
        ),
      ]),
    );
  }
}

final class _AdminFulfillmentItems extends StatelessWidget {
  const _AdminFulfillmentItems({required this.fulfillment});

  final AdminOrderFulfillment fulfillment;

  @override
  Widget build(BuildContext context) => _AdminFulfillmentBorder(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(child: Text('Items')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in fulfillment.items)
                  Text('${item.quantity}x ${item.title}'),
              ],
            ),
          ),
        ]),
      );
}

final class _AdminFulfillmentFact extends StatelessWidget {
  const _AdminFulfillmentFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => _AdminFulfillmentBorder(
        child: Row(children: [
          Expanded(child: Text(label)),
          Expanded(child: Text(value)),
        ]),
      );
}

final class _AdminFulfillmentTracking extends StatelessWidget {
  const _AdminFulfillmentTracking({required this.fulfillment});

  final AdminOrderFulfillment fulfillment;

  @override
  Widget build(BuildContext context) => _AdminFulfillmentBorder(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(child: Text('Tracking')),
          Expanded(
            child: fulfillment.labels.isEmpty
                ? const Text('-')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final label in fulfillment.labels)
                        SelectableText(
                          label.trackingNumber.isEmpty
                              ? label.trackingUrl
                              : label.trackingNumber,
                        ),
                    ],
                  ),
          ),
        ]),
      );
}

final class _AdminFulfillmentCardActions extends StatelessWidget {
  const _AdminFulfillmentCardActions({
    required this.order,
    required this.fulfillment,
  });

  final AdminOrderFulfillment fulfillment;
  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerRight,
        child: AdminCreateShipmentAction(
          order: order,
          fulfillment: fulfillment,
        ),
      );
}

final class _AdminFulfillmentBorder extends StatelessWidget {
  const _AdminFulfillmentBorder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          child: child,
        ),
      );
}

({String label, DateTime date}) _status(AdminOrderFulfillment fulfillment) =>
    switch ((
      fulfillment.canceledAt,
      fulfillment.deliveredAt,
      fulfillment.shippedAt,
    )) {
      (Some(:final value), _, _) => (label: 'Canceled', date: value),
      (_, Some(:final value), _) => (label: 'Delivered', date: value),
      (_, _, Some(:final value)) => (label: 'Shipped', date: value),
      _ => (label: 'Awaiting shipping', date: fulfillment.createdAt),
    };

String _providerName(String value) => value
    .split(RegExp('[-_]'))
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
