import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'account_section.dart';

/// Desktop account section navigation translated from Medusa AccountNav.
final class AccountNavigation extends StatelessWidget {
  /// Creates the navigation for [active].
  const AccountNavigation(
      {required this.state, required this.active, super.key});

  /// Active account route.
  final AccountSection active;

  /// Current session and sign-out state.
  final AccountState state;

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
          _link(
            context,
            AccountSection.overview,
            context.tr('shop_account_overview', defaultText: 'Overview'),
          ),
          _link(
            context,
            AccountSection.profile,
            context.tr('shop_account_profile', defaultText: 'Profile'),
          ),
          _link(
            context,
            AccountSection.addresses,
            context.tr('shop_account_addresses', defaultText: 'Addresses'),
          ),
          _link(
            context,
            AccountSection.orders,
            context.tr('shop_account_orders', defaultText: 'Orders'),
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

  Widget _link(
    BuildContext context,
    AccountSection section,
    String label,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextButton(
          onPressed: () => switch (section) {
            AccountSection.overview => context.navigator.account().go(),
            AccountSection.profile => context.navigator.accountProfile().go(),
            AccountSection.addresses =>
              context.navigator.accountAddresses().go(),
            AccountSection.orders => context.navigator.accountOrders().go(),
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            foregroundColor: section == active
                ? StoreColors.foreground
                : StoreColors.foregroundSubtle,
            textStyle: TextStyle(
              fontWeight: section == active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          child: Text(label),
        ),
      );
}
