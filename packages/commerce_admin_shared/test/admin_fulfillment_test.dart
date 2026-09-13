import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:test/test.dart';

void main() {
  test('round trips a Medusa order fulfillment command', () {
    const command = AdminCreateFulfillment(
      locationId: 'sloc_main',
      shippingOptionIdValue: 'ship_standard',
      noNotification: false,
      items: [
        AdminCreateFulfillmentItem(id: 'orditem_one', quantity: 2),
      ],
    );

    expect(command.toJson(), {
      'items': [
        {'id': 'orditem_one', 'quantity': 2},
      ],
      'location_id': 'sloc_main',
      'no_notification': false,
      'shipping_option_id': 'ship_standard',
    });
    expect(AdminCreateFulfillment.fromJson(command.toJson()), command);
    expect(command.shippingOptionId, const Some('ship_standard'));
  });

  test('represents a missing shipping option explicitly', () {
    final command = AdminCreateFulfillment.fromJson({
      'items': [
        {'id': 'orditem_one', 'quantity': 1},
      ],
      'location_id': 'sloc_main',
      'no_notification': true,
      'shipping_option_id': null,
    });

    expect(command.shippingOptionId, const None<String>());
    expect(command.noNotification, isTrue);
  });
}
