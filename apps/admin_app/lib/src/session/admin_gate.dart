import 'package:admin_app/src/product/admin_product_page.dart';
import 'package:admin_app/src/product/admin_product_view_model.dart';
import 'package:admin_app/src/session/admin_session_state.dart';
import 'package:admin_app/src/session/admin_session_view_model.dart';
import 'package:admin_app/src/session/admin_sign_in.dart';
import 'package:admin_app/src/shell/admin_shell.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.readAdminProductViewModel().load(offset: 0);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AdminShell(
        user: widget.user,
        themes: widget.themes,
        onSearchRequested: _searchFocus.requestFocus,
        onSignOut: widget.state.isBusy
            ? null
            : context.readAdminSessionViewModel().signOut,
        child: AdminProductPage(searchFocus: _searchFocus),
      );
}
