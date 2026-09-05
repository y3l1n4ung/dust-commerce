import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'account_section.dart';

/// Compact account navigation translated from Medusa's mobile AccountNav.
final class MobileAccountNavigation extends StatelessWidget {
  /// Creates compact navigation for the current account route.
  const MobileAccountNavigation({
    required this.customer,
    required this.state,
    required this.active,
    super.key,
  });

  /// Active account route.
  final AccountSection active;

  /// Server-proven customer.
  final Customer customer;

  /// Current session state.
  final AccountState state;

  @override
  Widget build(BuildContext context) {
    if (active != AccountSection.overview) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.navigator.account().go(),
          icon: const Icon(Icons.chevron_left, size: 18),
          label: const TranslatedText(
            'shop_account_title',
            defaultText: 'Account',
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(
            'shop_account_hello',
            defaultText: 'Hello {name}',
            args: {'name': customer.firstName ?? customer.displayName},
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _item(
          Icons.person_outline,
          context.tr('shop_account_profile', defaultText: 'Profile'),
          () => context.navigator.accountProfile().go(),
        ),
        _item(
          Icons.location_on_outlined,
          context.tr('shop_account_addresses', defaultText: 'Addresses'),
          () => context.navigator.accountAddresses().go(),
        ),
        _item(
          Icons.inventory_2_outlined,
          context.tr('shop_account_orders', defaultText: 'Orders'),
          () => context.navigator.accountOrders().go(),
        ),
        _item(
          Icons.logout,
          context.tr('shop_account_log_out', defaultText: 'Log out'),
          context.readAccountViewModel().signOut,
          enabled: !state.isBusy,
        ),
      ],
    );
  }

  Widget _item(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool enabled = true,
  }) =>
      Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, size: 20),
            title: Text(label),
            trailing: const Icon(Icons.chevron_right, size: 20),
            enabled: enabled,
            onTap: onTap,
          ),
          const Divider(height: 1),
        ],
      );
}
