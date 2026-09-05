import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Expandable product and delivery facts translated from Medusa `ProductTabs`.
class ProductTabs extends StatelessWidget {
  /// Creates the two independent product accordions.
  const ProductTabs({required this.details, super.key});

  /// Merchant facts for the loaded product.
  final ProductDetails details;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Divider(height: 1),
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding: const EdgeInsets.fromLTRB(4, 12, 4, 28),
            title: const TranslatedText(
              'shop_product_information',
              defaultText: 'Product Information',
            ),
            children: [_ProductInformation(details: details)],
          ),
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding: const EdgeInsets.fromLTRB(4, 12, 4, 28),
            title: const TranslatedText(
              'shop_shipping_returns',
              defaultText: 'Shipping & Returns',
            ),
            children: const [_ShippingInformation()],
          ),
          const Divider(height: 1),
        ],
      );
}

class _ProductInformation extends StatelessWidget {
  const _ProductInformation({required this.details});

  final ProductDetails details;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                _Fact(
                  label: context.tr('shop_material', defaultText: 'Material'),
                  value: details.material,
                ),
                _Fact(
                  label: context.tr(
                    'shop_origin_country',
                    defaultText: 'Country of origin',
                  ),
                  value: details.originCountry?.toUpperCase(),
                ),
                _Fact(
                  label: context.tr('shop_product_type', defaultText: 'Type'),
                  value: details.productType,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _Fact(
                  label: context.tr('shop_weight', defaultText: 'Weight'),
                  value: details.weight == null ? null : '${details.weight} g',
                ),
                _Fact(
                  label:
                      context.tr('shop_dimensions', defaultText: 'Dimensions'),
                  value: details.hasDimensions
                      ? '${details.length}L x ${details.width}W x ${details.height}H'
                      : null,
                ),
              ],
            ),
          ),
        ],
      );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(value ?? '-'),
            ],
          ),
        ),
      );
}

class _ShippingInformation extends StatelessWidget {
  const _ShippingInformation();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _ShippingFact(
            icon: Icons.local_shipping_outlined,
            title:
                context.tr('shop_fast_delivery', defaultText: 'Fast delivery'),
            body: context.tr(
              'shop_fast_delivery_body',
              defaultText:
                  'Your package will arrive in 3-5 business days at your pick up location or at home.',
            ),
          ),
          _ShippingFact(
            icon: Icons.refresh,
            title: context.tr(
              'shop_simple_exchanges',
              defaultText: 'Simple exchanges',
            ),
            body: context.tr(
              'shop_simple_exchanges_body',
              defaultText:
                  "If the fit is not right, we'll exchange your product for a new one.",
            ),
          ),
          _ShippingFact(
            icon: Icons.keyboard_return,
            title: context.tr('shop_easy_returns', defaultText: 'Easy returns'),
            body: context.tr(
              'shop_easy_returns_body',
              defaultText:
                  "Return your product for a refund. We'll make the process hassle-free.",
            ),
          ),
        ],
      );
}

class _ShippingFact extends StatelessWidget {
  const _ShippingFact({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String body;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      );
}
