import 'package:admin_app/src/product_option/admin_product_option_create_content.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:flutter/material.dart';

/// Opens the focused product-option creation surface from Medusa's list CTA.
Future<AdminProductOptionDetail?> showAdminProductOptionCreateDrawer(
  BuildContext context,
) =>
    showGeneralDialog<AdminProductOptionDetail>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close product option creator',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => const Padding(
        padding: EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerRight,
          child: AdminProductOptionCreateContent(),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
