import 'package:admin_app/src/shell/admin_sidebar.dart';
import 'package:admin_app/src/theme/admin_theme.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:flutter/material.dart';

/// Responsive Medusa-shaped frame shared by authenticated admin routes.
final class AdminShell extends StatelessWidget {
  /// Creates the merchant shell.
  const AdminShell({
    required this.user,
    required this.themes,
    required this.onSearchRequested,
    required this.onSignOut,
    required this.child,
    super.key,
  });

  /// Current route body.
  final Widget child;

  /// Focuses the active route search field.
  final VoidCallback onSearchRequested;

  /// Revokes the merchant session.
  final VoidCallback? onSignOut;

  /// Local appearance preference.
  final AdminThemeController themes;

  /// Proven merchant identity.
  final AdminUser user;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 900;
          final sidebar = AdminSidebar(
            user: user,
            themes: themes,
            onSearchRequested: onSearchRequested,
            onSignOut: onSignOut,
          );
          return Scaffold(
            drawer: desktop ? null : Drawer(width: 220, child: sidebar),
            body: Row(
              children: [
                if (desktop) SizedBox(width: 220, child: sidebar),
                Expanded(
                  child: Column(
                    children: [
                      _Topbar(desktop: desktop),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

final class _Topbar extends StatelessWidget {
  const _Topbar({required this.desktop});

  final bool desktop;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            if (!desktop)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Open navigation',
                  onPressed: Scaffold.of(context).openDrawer,
                  icon: const Icon(Icons.menu_rounded, size: 18),
                ),
              ),
            Text(
              'Products',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text('Notifications'),
                  content: Text("You're all caught up."),
                ),
              ),
              icon: const Icon(Icons.notifications_none_rounded, size: 18),
            ),
          ],
        ),
      );
}
