import 'dart:async';

import 'package:commerce_app/src/features/catalog/model/catalog_state.dart';
import 'package:commerce_app/src/features/catalog/view_model/catalog_view_model.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:dust_flutter/route.dart';
import 'package:flutter/material.dart';

/// The storefront's product listing.
///
/// The widget renders state and calls the view model. It decides nothing: what
/// counts as loading, empty, or failed is the view model's answer, read from
/// one place.
@AppRoute('/', name: 'catalog')
class CatalogPage extends StatefulWidget {
  /// Creates a [CatalogPage].
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  @override
  void initState() {
    super.initState();
    // read, not watch: a lifecycle callback is not a build.
    unawaited(context.readCatalogViewModel().load());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchCatalogViewModel().value;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('shop_title', defaultText: 'Shop'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (currency) =>
                context.readCatalogViewModel().changeCurrency(currency),
            itemBuilder: (_) => [
              for (final code in sellingCurrencies)
                PopupMenuItem(value: code, child: Text(code.toUpperCase())),
            ],
            child: Center(
              child: Text(state.currencyCode.toUpperCase()),
            ),
          ),
        ],
      ),
      body: switch (state.status) {
        CatalogStatus.idle ||
        CatalogStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        CatalogStatus.failed => _Failed(
            message: state.message ?? 'Something went wrong',
            onRetry: () => context.readCatalogViewModel().load(),
          ),
        CatalogStatus.ready when state.isEmpty => const Center(
            child: TranslatedText(
              'shop_empty',
              defaultText: 'Nothing for sale yet',
            ),
          ),
        CatalogStatus.ready => _ProductList(products: state.products),
      },
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final price = product.variants.isEmpty
            ? null
            : product.cheapestIn(
                product.variants.first.prices.first.currencyCode,
              );

        return ListTile(
          title: Text(product.title),
          subtitle: Text(price == null ? '—' : formatMoney(price)),
          trailing: product.isPurchasable
              ? null
              : const TranslatedText(
                  'shop_sold_out',
                  defaultText: 'Sold out',
                  style: TextStyle(color: Colors.grey),
                ),
        );
      },
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const TranslatedText(
              'shop_retry',
              defaultText: 'Try again',
            ),
          ),
        ],
      ),
    );
  }
}

/// The currencies the storefront offers.
///
/// Currency codes are data, not copy: `USD` is `USD` in every language, so
/// these are rendered from the list rather than written as literals a
/// translator would be asked to translate.
const sellingCurrencies = <String>['usd', 'eur'];

/// Renders [amount] the way a price is written.
///
/// Minor units are divided only here, at the very edge, for display. Every
/// other layer keeps the integer, which is what stops a rounding error being
/// introduced by arithmetic nobody meant to do.
String formatMoney(Money amount) {
  final major = amount.amount ~/ 100;
  final minor = (amount.amount % 100).toString().padLeft(2, '0');
  return '${amount.currencyCode.toUpperCase()} $major.$minor';
}
