import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:admin_app/src/product/detail/admin_product_general_section.dart';
import 'package:admin_app/src/product/detail/admin_product_media_section.dart';
import 'package:admin_app/src/product/detail/admin_product_option_section.dart';
import 'package:admin_app/src/product/detail/admin_product_sidebar_sections.dart';
import 'package:admin_app/src/product/detail/admin_product_variant_section.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Complete Medusa-shaped merchant product detail route.
final class AdminProductDetailPage extends StatefulWidget {
  /// Creates a detail route for [productId].
  const AdminProductDetailPage({
    required this.productId,
    required this.onBack,
    super.key,
  });

  /// Returns to the product table.
  final VoidCallback onBack;

  /// Stable product identifier loaded from the admin API.
  final String productId;

  @override
  State<AdminProductDetailPage> createState() => _AdminProductDetailPageState();
}

final class _AdminProductDetailPageState extends State<AdminProductDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.readAdminProductDetailViewModel().load(widget.productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminProductDetailViewModel().value;
    return switch (state.product) {
      Some(value: final product) => _DetailBody(
          product: product,
          onBack: widget.onBack,
        ),
      None() when state.status == AdminProductDetailStatus.loading =>
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      None() => _Failure(
          state: state,
          onBack: widget.onBack,
          onRetry: () =>
              context.readAdminProductDetailViewModel().load(widget.productId),
        ),
    };
  }
}

final class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.product, required this.onBack});

  final VoidCallback onBack;
  final AdminProductDetail product;

  @override
  Widget build(BuildContext context) {
    void unavailable() => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This action needs the next Admin API slice.'),
          ),
        );

    final main = Column(
      children: [
        AdminProductGeneralSection(
          product: product,
          onUnavailable: unavailable,
        ),
        const SizedBox(height: 12),
        AdminProductMediaSection(
          product: product,
          onUnavailable: unavailable,
        ),
        const SizedBox(height: 12),
        AdminProductOptionSection(
          options: product.options,
          onUnavailable: unavailable,
        ),
        const SizedBox(height: 12),
        AdminProductVariantSection(
          variants: product.variants,
          onUnavailable: unavailable,
        ),
      ],
    );
    final side = AdminProductSidebarSections(
      product: product,
      onUnavailable: unavailable,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Products'),
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 900
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: main),
                          const SizedBox(width: 12),
                          Expanded(flex: 3, child: side),
                        ],
                      )
                    : Column(
                        children: [
                          main,
                          const SizedBox(height: 12),
                          side,
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _Failure extends StatelessWidget {
  const _Failure({
    required this.state,
    required this.onBack,
    required this.onRetry,
  });

  final VoidCallback onBack;
  final VoidCallback onRetry;
  final AdminProductDetailState state;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(switch (state.failure) {
              Some(value: final message) => message,
              None() => 'Unable to load this product.',
            }),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: onBack, child: const Text('Products')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ],
        ),
      );
}
