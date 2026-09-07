import 'dart:async';

import 'package:admin_app/src/product/admin_product_detail_media_actions.dart';
import 'package:admin_app/src/product/admin_product_detail_failure.dart';
import 'package:admin_app/src/product/admin_product_detail_state.dart';
import 'package:admin_app/src/product/admin_product_detail_view_model.dart';
import 'package:admin_app/src/product/admin_product_edit_drawer.dart';
import 'package:admin_app/src/product/admin_product_media_editor.dart';
import 'package:admin_app/src/product/admin_product_variant_edit_drawer.dart';
import 'package:admin_app/src/product/admin_product_view_model.dart';
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
    required this.onOpenOption,
    super.key,
  });

  /// Returns to the product table.
  final VoidCallback onBack;

  /// Opens one linked option on its dedicated Medusa route.
  final ValueChanged<String> onOpenOption;

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
          onOpenOption: widget.onOpenOption,
        ),
      None() when state.status == AdminProductDetailStatus.loading =>
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      None() => AdminProductDetailFailure(
          state: state,
          onBack: widget.onBack,
          onRetry: () =>
              context.readAdminProductDetailViewModel().load(widget.productId),
        ),
    };
  }
}

final class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.product,
    required this.onBack,
    required this.onOpenOption,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onOpenOption;
  final AdminProductDetail product;

  @override
  Widget build(BuildContext context) {
    Future<void> editGeneral() async {
      final saved = await showAdminProductEditDrawer(context, product);
      if (saved != true || !context.mounted) return;
      unawaited(context.readAdminProductViewModel().load());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated.')),
      );
    }

    Future<void> editMedia() async {
      final saved = await showAdminProductMediaEditor(context, product);
      if (saved != true || !context.mounted) return;
      unawaited(context.readAdminProductViewModel().load());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product media updated.')),
      );
    }

    Future<void> editVariant(AdminProductVariant variant) async {
      final saved = await showAdminProductVariantEditDrawer(
        context,
        product,
        variant,
      );
      if (saved != true || !context.mounted) return;
      unawaited(context.readAdminProductViewModel().load());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variant updated.')),
      );
    }

    final main = Column(
      children: [
        AdminProductGeneralSection(
          product: product,
          onEdit: editGeneral,
        ),
        const SizedBox(height: 12),
        AdminProductMediaSection(
          product: product,
          onEdit: editMedia,
          onDelete: (ids) => deleteAdminProductMedia(context, product, ids),
          onManageVariants: (image) =>
              manageAdminProductImageVariants(context, product, image),
        ),
        const SizedBox(height: 12),
        AdminProductOptionSection(
          options: product.options,
          onOpen: (option) => onOpenOption(option.id),
          onUnavailable: () => showAdminUnavailable(context),
        ),
        const SizedBox(height: 12),
        AdminProductVariantSection(
          variants: product.variants,
          onEdit: editVariant,
          onUnavailable: () => showAdminUnavailable(context),
        ),
      ],
    );
    final side = AdminProductSidebarSections(
      product: product,
      onUnavailable: () => showAdminUnavailable(context),
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
