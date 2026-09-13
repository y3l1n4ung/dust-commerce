import 'package:admin_app/src/order/admin_fulfillment_draft.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_order_detail_fixture.dart';

void main() {
  test('subtracts active fulfillment quantities by order line', () {
    final order = AdminOrderDetail.fromJson({
      ...adminFulfilledOrderDetailJson,
      'items': [
        ...(adminFulfilledOrderDetailJson['items']! as List<Object?>),
        {
          'id': 'item_shirt',
          'variant_id': 'var_shirt',
          'product_id': 'prod_shirt',
          'shipping_profile_id': 'sp_default',
          'product_handle': 't-shirt',
          'thumbnail': null,
          'title': 'T-Shirt',
          'variant_title': 'M / Black',
          'unit_amount': 2000,
          'currency_code': 'eur',
          'quantity': 2,
          'created_at': '2026-09-10T10:00:01.000Z',
        },
      ],
    });

    expect(adminFulfillableQuantities(order), {'item_shirt': 2});
  });

  test('builds only positive profile-compatible command items', () {
    final order = AdminOrderDetail.fromJson(adminOrderDetailJson);
    const option = AdminFulfillmentShippingOption(
      id: 'ship_eu_standard',
      name: 'Standard shipping',
      shippingProfileId: 'sp_default',
    );

    final command = buildAdminFulfillmentCommand(
      order: order,
      locationId: 'sloc_main',
      shippingOption: option,
      quantities: const {'item_cup': 1, 'unknown': 99},
    );

    expect(command, isA<Some<AdminCreateFulfillment>>());
    expect(
        (command as Some<AdminCreateFulfillment>).value,
        const AdminCreateFulfillment(
          items: [AdminCreateFulfillmentItem(id: 'item_cup', quantity: 1)],
          locationId: 'sloc_main',
          noNotification: true,
          shippingOptionIdValue: 'ship_eu_standard',
        ));
  });

  test('rejects empty, incompatible, and excessive drafts', () {
    final order = AdminOrderDetail.fromJson(adminOrderDetailJson);
    const wrongProfile = AdminFulfillmentShippingOption(
      id: 'ship_wrong',
      name: 'Freight',
      shippingProfileId: 'sp_freight',
    );

    expect(
      buildAdminFulfillmentCommand(
        order: order,
        locationId: 'sloc_main',
        shippingOption: wrongProfile,
        quantities: const {'item_cup': 1},
      ),
      const None<AdminCreateFulfillment>(),
    );
    expect(
      buildAdminFulfillmentCommand(
        order: order,
        locationId: 'sloc_main',
        shippingOption: wrongProfile,
        quantities: const {'item_cup': 2},
      ),
      const None<AdminCreateFulfillment>(),
    );
  });
}
