import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Desktop account section navigation.
class AccountNavigation extends StatelessWidget {
  /// Creates the navigation.
  const AccountNavigation({
    required this.state,
    this.ordersActive = false,
    super.key,
  });

  /// Current account state.
  final AccountState state;

  /// Whether the order-history route is active.
  final bool ordersActive;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'shop_account_title',
            defaultText: 'Account',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.navigator.account().go(),
            style: _navigationStyle(active: !ordersActive),
            child: const TranslatedText(
              'shop_account_overview',
              defaultText: 'Overview',
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.navigator.accountOrders().go(),
            style: _navigationStyle(active: ordersActive),
            child: const TranslatedText(
              'shop_account_orders',
              defaultText: 'Orders',
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed:
                state.isBusy ? null : context.readAccountViewModel().signOut,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: state.operation == AccountOperation.signOut && state.isBusy
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const TranslatedText(
                    'shop_account_log_out',
                    defaultText: 'Log out',
                  ),
          ),
          if (state.status == AccountStatus.failed &&
              state.operation == AccountOperation.signOut) ...[
            const SizedBox(height: 12),
            Text(
              state.message ?? '',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      );

  ButtonStyle _navigationStyle({required bool active}) => TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        foregroundColor:
            active ? StoreColors.foreground : StoreColors.foregroundSubtle,
        textStyle: TextStyle(
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      );
}

/// Compact account navigation used below the desktop breakpoint.
class MobileAccountNavigation extends StatelessWidget {
  /// Creates compact navigation.
  const MobileAccountNavigation({
    required this.customer,
    required this.state,
    super.key,
  });

  /// Server-proven customer.
  final Customer customer;

  /// Current account state.
  final AccountState state;

  @override
  Widget build(BuildContext context) => Column(
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
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline, size: 20),
            title: TranslatedText(
              'shop_account_overview',
              defaultText: 'Overview',
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2_outlined, size: 20),
            title: const TranslatedText(
              'shop_account_orders',
              defaultText: 'Orders',
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.navigator.accountOrders().go(),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, size: 20),
            title: const TranslatedText(
              'shop_account_log_out',
              defaultText: 'Log out',
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            enabled: !state.isBusy,
            onTap: context.readAccountViewModel().signOut,
          ),
        ],
      );
}
