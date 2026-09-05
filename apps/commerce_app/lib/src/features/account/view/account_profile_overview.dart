import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Customer identity and recent activity summary.
class AccountProfileOverview extends StatelessWidget {
  /// Creates the profile overview.
  const AccountProfileOverview({required this.customer, super.key});

  /// Server-proven customer.
  final Customer customer;

  int get _completion {
    var completed = 1;
    if ((customer.firstName?.isNotEmpty ?? false) &&
        (customer.lastName?.isNotEmpty ?? false)) {
      completed++;
    }
    if (customer.phone?.isNotEmpty ?? false) completed++;
    return (completed / 3 * 100).round();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              Text(
                context.tr(
                  'shop_account_hello',
                  defaultText: 'Hello {name}',
                  args: {'name': customer.firstName ?? customer.displayName},
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text.rich(
                TextSpan(
                  text: context.tr(
                    'shop_account_signed_in_as',
                    defaultText: 'Signed in as: ',
                  ),
                  children: [
                    TextSpan(
                      text: customer.email,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 32),
          const TranslatedText(
            'shop_account_profile',
            defaultText: 'Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_completion%',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const TranslatedText(
                'shop_account_completed',
                defaultText: 'COMPLETED',
                style: TextStyle(
                  color: StoreColors.foregroundSubtle,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const TranslatedText(
            'shop_account_recent_orders',
            defaultText: 'Recent orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const TranslatedText(
            'shop_account_no_orders',
            defaultText: 'No recent orders',
          ),
        ],
      );
}
