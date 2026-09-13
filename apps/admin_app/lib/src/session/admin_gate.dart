import 'package:admin_app/src/product/admin_product_page.dart';
import 'package:admin_app/src/product/admin_product_detail_page.dart';
import 'package:admin_app/src/product/admin_product_create_page.dart';
import 'package:admin_app/src/product/admin_product_view_model.dart';
import 'package:admin_app/src/order/admin_order_page.dart';
import 'package:admin_app/src/order/admin_order_view_model.dart';
import 'package:admin_app/src/product_option/admin_product_option_create_page.dart';
import 'package:admin_app/src/product_option/admin_product_option_detail_page.dart';
import 'package:admin_app/src/product_option/admin_product_option_detail_view_model.dart';
import 'package:admin_app/src/product_option/admin_product_option_page.dart';
import 'package:admin_app/src/product_option/admin_product_option_view_model.dart';
import 'package:admin_app/src/product_type/admin_product_type_page.dart';
import 'package:admin_app/src/product_type/admin_product_type_detail_page.dart';
import 'package:admin_app/src/product_type/admin_product_type_detail_view_model.dart';
import 'package:admin_app/src/product_type/admin_product_type_view_model.dart';
import 'package:admin_app/src/session/admin_session_state.dart';
import 'package:admin_app/src/session/admin_session_view_model.dart';
import 'package:admin_app/src/session/admin_sign_in.dart';
import 'package:admin_app/src/shell/admin_shell.dart';
import 'package:admin_app/src/shell/admin_shell_section.dart';
import 'package:admin_app/src/theme/admin_theme.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

part 'admin_gate_navigation.dart';

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

final class _AdminHomeState extends State<_AdminHome>
    with _AdminHomeNavigation {
  @override
  final _orderSearchFocus = FocusNode();
  @override
  final _searchFocus = FocusNode();
  @override
  final _optionSearchFocus = FocusNode();
  @override
  final _typeSearchFocus = FocusNode();
  @override
  _AdminRoute _route = _AdminRoute.products;
  @override
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
    _orderSearchFocus.dispose();
    _searchFocus.dispose();
    _optionSearchFocus.dispose();
    _typeSearchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildAdminHome(context);
}

enum _AdminRoute {
  orders,
  products,
  product,
  productOptions,
  productOption,
  productTypes,
  productType,
}
