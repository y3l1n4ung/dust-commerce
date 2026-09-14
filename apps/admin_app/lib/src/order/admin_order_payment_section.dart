import 'package:admin_app/src/core/admin_money.dart';
import 'package:admin_app/src/order/admin_order_status_badge.dart';
import 'package:admin_app/src/product/detail/admin_product_detail_section.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Provider payment facts without capture or refund controls.
final class AdminOrderPaymentSection extends StatelessWidget {
  /// Creates the payment section.
  const AdminOrderPaymentSection({required this.order, super.key});

  /// Complete merchant order snapshot.
  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) => AdminProductDetailSection(
        title: 'Payment',
        action: AdminOrderPaymentBadge(status: order.paymentStatus),
        child: Column(children: [
          switch (order.paymentProvider) {
            Some(value: final provider) => AdminProductDetailRow(
                label: 'Provider',
                value: Text(provider),
              ),
            None() => AdminProductDetailRow(
                label: 'Payment record',
                value: adminDetailText(context, null),
              ),
          },
          if (order.paymentRecordStatus case Some(value: final status))
            AdminProductDetailRow(
              label: 'Status',
              value: Text(_recordLabel(status)),
            ),
          if (order.paymentCreatedAt case Some(value: final createdAt))
            AdminProductDetailRow(
              label: 'Created',
              value: Text(_date(createdAt)),
            ),
          if (order.paymentCapturedAt case Some(value: final capturedAt))
            AdminProductDetailRow(
              label: 'Captured',
              value: Text(_date(capturedAt)),
            ),
          AdminProductDetailRow(
            label: 'Amount',
            value: Text(switch (order.paymentAmount) {
              Some(value: final amount) =>
                '${order.currencyCode.toUpperCase()} '
                    '${formatMinorUnits(amount, order.currencyCode)}',
              None() => '—',
            }),
          ),
        ]),
      );

  String _date(DateTime value) =>
      DateFormat.yMMMd().add_jm().format(value.toLocal());

  String _recordLabel(AdminOrderPaymentRecordStatus status) => switch (status) {
        AdminOrderPaymentRecordStatus.pending => 'Pending',
        AdminOrderPaymentRecordStatus.authorized => 'Authorized',
        AdminOrderPaymentRecordStatus.captured => 'Captured',
        AdminOrderPaymentRecordStatus.canceled => 'Canceled',
        AdminOrderPaymentRecordStatus.failed => 'Failed',
      };
}
