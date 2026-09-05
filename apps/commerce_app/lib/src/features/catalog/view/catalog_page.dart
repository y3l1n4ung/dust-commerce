import 'dart:async';

import 'package:commerce_app/commerce_app.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:dust_flutter/route.dart';
import 'package:flutter/material.dart';

/// Home and featured-product rail translated from the Medusa DTC source.
@AppRoute('/', name: 'catalog', guards: [])
class CatalogPage extends StatefulWidget {
  /// Creates the storefront home.
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.readCatalogViewModel().load());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchCatalogViewModel().value;
    return StoreScaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Hero()),
          SliverToBoxAdapter(child: _CatalogHeader(total: state.total)),
          switch (state.status) {
            CatalogStatus.idle ||
            CatalogStatus.loading =>
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            CatalogStatus.failed => SliverFillRemaining(
                child: _Failure(
                  message: state.message ?? 'Something went wrong',
                  onRetry: () => context.readCatalogViewModel().load(),
                ),
              ),
            CatalogStatus.ready when state.isEmpty => const SliverFillRemaining(
                child: Center(
                  child: TranslatedText(
                    'shop_empty',
                    defaultText: 'Nothing for sale yet',
                  ),
                ),
              ),
            CatalogStatus.ready => SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _columns(
                      MediaQuery.sizeOf(context).width,
                    ),
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 48,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (_, index) => ProductCard(
                    product: state.products[index],
                    currencyCode: state.currencyCode,
                  ),
                ),
              ),
          },
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        constraints: const BoxConstraints(minHeight: 440),
        decoration: const BoxDecoration(
          color: StoreColors.subtle,
          border: Border(
            bottom: BorderSide(color: StoreColors.border),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TranslatedText(
                'shop_hero_title',
                defaultText: 'Everyday essentials, considered.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, height: 1.3),
              ),
              const TranslatedText(
                'shop_hero_subtitle',
                defaultText: 'Powered by dust',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.3,
                  color: StoreColors.foregroundSubtle,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => PrimaryScrollController.of(context).animateTo(
                  MediaQuery.sizeOf(context).height * 0.72,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                ),
                child: const TranslatedText(
                  'shop_products_action',
                  defaultText: 'Shop products',
                ),
              ),
            ],
          ),
        ),
      );
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const TranslatedText(
              'shop_featured_products',
              defaultText: 'Featured products',
              style: TextStyle(fontSize: 22),
            ),
            Text(
              context.tr(
                'shop_product_count',
                defaultText: '{count} products',
                args: {'count': total},
              ),
              style: const TextStyle(color: StoreColors.foregroundMuted),
            ),
          ],
        ),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
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

int _columns(double width) => width >= 1100
    ? 4
    : width >= 700
        ? 3
        : 2;
