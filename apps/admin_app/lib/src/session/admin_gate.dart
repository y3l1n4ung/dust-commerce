import 'package:admin_app/src/product/admin_product_page.dart';
import 'package:admin_app/src/product/admin_product_detail_page.dart';
import 'package:admin_app/src/product/admin_product_create_page.dart';
import 'package:admin_app/src/product/admin_product_view_model.dart';
import 'package:admin_app/src/product_option/admin_product_option_create_page.dart';
import 'package:admin_app/src/product_option/admin_product_option_detail_page.dart';
import 'package:admin_app/src/product_option/admin_product_option_detail_view_model.dart';
import 'package:admin_app/src/product_option/admin_product_option_page.dart';
import 'package:admin_app/src/product_option/admin_product_option_view_model.dart';
import 'package:admin_app/src/session/admin_session_state.dart';
import 'package:admin_app/src/session/admin_session_view_model.dart';
import 'package:admin_app/src/session/admin_sign_in.dart';
import 'package:admin_app/src/shell/admin_shell.dart';
import 'package:admin_app/src/shell/admin_shell_section.dart';
import 'package:admin_app/src/theme/admin_theme.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Switches between sign-in and the authenticated admin shell.
final class AdminGate extends StatelessWidget {
  /// Creates the gate.
  const AdminGate({required this.themes, super.key});

  /// Local merchant appearance preference.
  final AdminThemeController themes;

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminSessionViewModel().value;
    return switch (state.user) {
      Some(value: final user) => _AdminHome(
          user: user,
          state: state,
          themes: themes,
        ),
      None() when state.status == AdminSessionStatus.initial || state.isBusy =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      None() => AdminSignIn(state: state),
    };
  }
}

final class _AdminHome extends StatefulWidget {
  const _AdminHome({
    required this.user,
    required this.state,
    required this.themes,
  });

  final AdminSessionState state;
  final AdminThemeController themes;
  final AdminUser user;

  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

final class _AdminHomeState extends State<_AdminHome> {
  final _searchFocus = FocusNode();
  final _optionSearchFocus = FocusNode();
  _AdminRoute _route = _AdminRoute.products;
  String _selectedId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.readAdminProductViewModel()
        ..load(offset: 0)
        ..loadFilterOptions();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _optionSearchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final optionDetail =
        context.watchAdminProductOptionDetailViewModel().value.productOption;
    return AdminShell(
      user: widget.user,
      themes: widget.themes,
      title: switch (_route) {
        _AdminRoute.products => 'Products',
        _AdminRoute.product => 'Product details',
        _AdminRoute.productOptions => 'Options',
        _AdminRoute.productOption => switch (optionDetail) {
            Some(value: final option) => 'Options  ›  ${option.title}',
            None() => 'Options',
          },
      },
      onSearchRequested: () {
        final options = _route == _AdminRoute.productOptions ||
            _route == _AdminRoute.productOption;
        if (options) {
          _showProductOptions();
        } else {
          _showProducts();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            (options ? _optionSearchFocus : _searchFocus).requestFocus();
          }
        });
      },
      onProductsRequested: _showProducts,
      onProductOptionsRequested: _showProductOptions,
      selectedSection: switch (_route) {
        _AdminRoute.products ||
        _AdminRoute.product =>
          AdminShellSection.products,
        _AdminRoute.productOptions ||
        _AdminRoute.productOption =>
          AdminShellSection.productOptions,
      },
      onSignOut: widget.state.isBusy
          ? null
          : context.readAdminSessionViewModel().signOut,
      child: switch (_route) {
        _AdminRoute.product => AdminProductDetailPage(
            productId: _selectedId,
            onBack: _showProducts,
            onOpenOption: _showProductOption,
          ),
        _AdminRoute.products => AdminProductPage(
            searchFocus: _searchFocus,
            onCreateProduct: _createProduct,
            onOpenProduct: _showProduct,
          ),
        _AdminRoute.productOptions => AdminProductOptionPage(
            searchFocus: _optionSearchFocus,
            onOpen: _showProductOption,
            onCreate: _createProductOption,
          ),
        _AdminRoute.productOption => AdminProductOptionDetailPage(
            productOptionId: _selectedId,
            onBack: _showProductOptions,
            onOpenProduct: _showProduct,
          ),
      },
    );
  }

  void _showProducts() => setState(() {
        _route = _AdminRoute.products;
        _selectedId = '';
      });

  void _showProduct(String id) => setState(() {
        _route = _AdminRoute.product;
        _selectedId = id;
      });

  void _showProductOptions() {
    context.readAdminProductOptionViewModel().load(offset: 0);
    setState(() {
      _route = _AdminRoute.productOptions;
      _selectedId = '';
    });
  }

  void _showProductOption(String id) => setState(() {
        _route = _AdminRoute.productOption;
        _selectedId = id;
      });

  Future<void> _createProduct() async {
    final created = await showAdminProductCreatePage(context);
    if (!mounted) return;
    if (created case Some(value: final product)) {
      await context.readAdminProductViewModel().load(offset: 0);
      if (mounted) _showProduct(product.id);
    }
  }

  Future<void> _createProductOption() async {
    final created = await showAdminProductOptionCreatePage(context);
    if (!mounted || created == null) return;
    _showProductOption(created.id);
  }
}

enum _AdminRoute { products, product, productOptions, productOption }
