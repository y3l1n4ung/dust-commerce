import 'package:admin_app/src/shell/admin_user_menu.dart';
import 'package:admin_app/src/shell/admin_shell_section.dart';
import 'package:admin_app/src/theme/admin_theme.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:flutter/material.dart';

part 'admin_sidebar_subnav.dart';

/// Medusa Admin's compact navigation hierarchy with Morrow identity.
final class AdminSidebar extends StatelessWidget {
  /// Creates the admin navigation.
  const AdminSidebar({
    required this.user,
    required this.themes,
    required this.onSearchRequested,
    required this.onProductsRequested,
    required this.onProductOptionsRequested,
    required this.selectedSection,
    required this.onSignOut,
    super.key,
  });

  /// Focuses the active product search field.
  final VoidCallback onSearchRequested;

  /// Returns to the product catalogue route.
  final VoidCallback onProductsRequested;

  /// Opens the global product-options route.
  final VoidCallback onProductOptionsRequested;

  /// Revokes the current admin session.
  final VoidCallback? onSignOut;

  /// Current product navigation branch.
  final AdminShellSection selectedSection;

  /// Local appearance preference.
  final AdminThemeController themes;

  /// Proven merchant rendered in the utility menu.
  final AdminUser user;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _StoreHeader(user: user),
                const SizedBox(height: 12),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                const SizedBox(height: 10),
                _NavRow(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  shortcut: '⌘K',
                  onTap: onSearchRequested,
                ),
                const _NavRow(
                    icon: Icons.receipt_long_outlined, label: 'Orders'),
                _NavRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  selected: selectedSection == AdminShellSection.products,
                  onTap: onProductsRequested,
                ),
                const _SubNav(label: 'Collections'),
                const _SubNav(label: 'Categories'),
                _SubNav(
                  label: 'Options',
                  selected: selectedSection == AdminShellSection.productOptions,
                  onTap: onProductOptionsRequested,
                ),
                const _NavRow(
                    icon: Icons.warehouse_outlined, label: 'Inventory'),
                const _SubNav(label: 'Reservations'),
                const _NavRow(icon: Icons.people_outline, label: 'Customers'),
                const _SubNav(label: 'Customer Groups'),
                const _NavRow(icon: Icons.sell_outlined, label: 'Promotions'),
                const _SubNav(label: 'Campaigns'),
                const _NavRow(
                    icon: Icons.list_alt_outlined, label: 'Price Lists'),
                const Spacer(),
                const _NavRow(icon: Icons.settings_outlined, label: 'Settings'),
                const SizedBox(height: 8),
                AdminUserMenu(
                  user: user,
                  themes: themes,
                  onSignOut: onSignOut,
                ),
              ],
            ),
          ),
        ),
      );
}

final class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30,
        child: Row(
          children: [
            const AdminAvatar(label: 'M'),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Morrow', overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              tooltip: 'Store actions',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded, size: 17),
            ),
          ],
        ),
      );
}

final class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    this.selected = false,
    this.shortcut,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final String? shortcut;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: selected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: selected
                ? BorderSide(color: Theme.of(context).dividerColor)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: SizedBox(
              height: 30,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(icon, size: 16),
                  const SizedBox(width: 9),
                  Expanded(child: Text(label)),
                  if (shortcut case final value?)
                    Text(value, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      );
}
