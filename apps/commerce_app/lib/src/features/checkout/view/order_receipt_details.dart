import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Shipping address, contact, and delivery method from the frozen order.
final class OrderShippingDetails extends StatelessWidget {
  /// Creates the shipping detail block.
  const OrderShippingDetails({required this.order, super.key});

  /// Frozen paid order.
  final Order order;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TranslatedText(
            'shop_checkout_delivery',
            defaultText: 'Delivery',
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 56,
            runSpacing: 24,
            children: [
              _detail(
                  context.tr(
                    'shop_checkout_shipping_address',
                    defaultText: 'Shipping Address',
                  ),
                  [
                    order.shippingAddress.fullName,
                    order.shippingAddress.line1,
                    if (order.shippingAddress.line2 case final line?) line,
                    '${order.shippingAddress.postalCode}, ${order.shippingAddress.city}',
                    order.shippingAddress.countryCode.toUpperCase(),
                  ]),
              _detail(
                  context.tr(
                    'shop_checkout_contact',
                    defaultText: 'Contact',
                  ),
                  [
                    if (order.shippingAddress.phone case final phone?) phone,
                    order.email,
                  ]),
              _detail(
                  context.tr(
                    'shop_checkout_method',
                    defaultText: 'Method',
                  ),
                  [
                    if (order.shippingMethod case final method?)
                      '${method.name} ${formatMoney(method.amount)}'
                    else
                      context.tr(
                        'shop_checkout_delivery',
                        defaultText: 'Delivery',
                      ),
                  ]),
            ],
          ),
        ],
      );

  Widget _detail(String title, List<String> lines) => SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final line in lines)
              Text(line,
                  style: const TextStyle(color: StoreColors.foregroundSubtle)),
          ],
        ),
      );
}

/// Payment provider and final payment status.
final class OrderPaymentDetails extends StatelessWidget {
  /// Creates the payment detail block.
  const OrderPaymentDetails({required this.order, super.key});

  /// Frozen paid order.
  final Order order;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TranslatedText(
            'shop_checkout_payment',
            defaultText: 'Payment',
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _PaymentDetail(
                  title: context.tr(
                    'shop_checkout_payment_method',
                    defaultText: 'Payment method',
                  ),
                  value: context.tr(
                    'shop_checkout_manual_payment',
                    defaultText: 'Manual Payment',
                  ),
                ),
              ),
              Expanded(
                child: _PaymentDetail(
                  title: context.tr(
                    'shop_checkout_payment_details',
                    defaultText: 'Payment details',
                  ),
                  value: order.paymentStatus == PaymentStatus.captured
                      ? context.tr(
                          'shop_checkout_captured',
                          defaultText: 'Captured',
                        )
                      : context.tr(
                          'shop_checkout_awaiting_payment',
                          defaultText: 'Awaiting payment',
                        ),
                ),
              ),
            ],
          ),
        ],
      );
}

final class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(color: StoreColors.foregroundSubtle)),
        ],
      );
}
