import 'package:commerce_app/commerce_app.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Account help footer from the source layout.
class AccountSupport extends StatelessWidget {
  /// Creates the help footer.
  const AccountSupport({super.key});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TranslatedText(
                  'shop_account_questions',
                  defaultText: 'Got questions?',
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(
                    'shop_account_questions_body',
                    defaultText: 'You can find frequently asked questions and '
                        'answers on our customer service page.',
                  ),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const TranslatedText(
            'shop_account_customer_service',
            defaultText: 'Customer Service',
            style: TextStyle(color: StoreColors.foregroundSubtle),
          ),
        ],
      );
}
