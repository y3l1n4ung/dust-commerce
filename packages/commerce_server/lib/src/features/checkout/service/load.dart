import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/features/checkout/repository/repository.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/db.dart';

/// Builds the domain [Address] a row describes.
Address addressOf(OrderAddressRow row) => Address(
      firstName: row.firstName,
      lastName: row.lastName,
      line1: row.line1,
      line2: row.line2,
      city: row.city,
      province: row.province,
      postalCode: row.postalCode,
      countryCode: row.countryCode,
      phone: row.phone,
    );

/// Assembles the domain [Order] from a header row, its lines and addresses.
///
/// The totals come from the header, not from re-adding the lines. They were
/// frozen when the order was placed, and recomputing them here would quietly
/// undo that the first time a tax rate changed.
Order orderOf(
  OrderRow row,
  List<LineItemRow> items,
  List<OrderAddressRow> addresses,
) {
  final shipping = addresses.where((it) => it.kind == 'shipping').first;
  final billing =
      addresses.where((it) => it.kind == 'billing').firstOrNull ?? shipping;

  return Order(
    id: row.id,
    email: row.email,
    customerId: row.customerId,
    region: regionOf(
      id: row.regionId,
      name: row.regionName,
      currencyCode: row.currencyCode,
      taxRate: row.taxRate,
      taxInclusive: row.taxInclusive,
      countries: row.countries,
    ),
    items: items.map(lineOf).toList(growable: false),
    subtotal: Money(amount: row.subtotal, currencyCode: row.currencyCode),
    tax: Money(amount: row.tax, currencyCode: row.currencyCode),
    total: Money(amount: row.total, currencyCode: row.currencyCode),
    shippingAddress: addressOf(shipping),
    billingAddress: addressOf(billing),
    placedAt: DateTime.parse(row.placedAt),
    status: _orderStatus(row.status),
    paymentStatus: _paymentStatus(row.paymentStatus),
  );
}

/// One order by id, or `Ok(null)` when there is none.
Future<Result<Order?, SqlxError>> loadOrder(
  CheckoutRepository repository,
  String orderId,
) async {
  final found = await repository.findOrder(orderId);
  if (found case Err(:final error)) return Err(error);

  final row = (found as Ok<OrderRow?, SqlxError>).value;
  if (row == null) return const Ok(null);

  final items = await repository.itemsOf(orderId);
  if (items case Err(:final error)) return Err(error);

  final addresses = await repository.addressesOf(orderId);
  if (addresses case Err(:final error)) return Err(error);

  return Ok(
    orderOf(
      row,
      (items as Ok<List<LineItemRow>, SqlxError>).value,
      (addresses as Ok<List<OrderAddressRow>, SqlxError>).value,
    ),
  );
}

OrderStatus _orderStatus(String stored) {
  for (final status in OrderStatus.values) {
    if (status.name == stored) return status;
  }
  return OrderStatus.pending;
}

PaymentStatus _paymentStatus(String stored) {
  for (final status in PaymentStatus.values) {
    if (status.name == stored) return status;
  }
  return PaymentStatus.awaiting;
}
