import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';

import 'account_navigation.dart';
import 'account_profile_overview.dart';
import 'account_support.dart';

/// Authenticated Medusa account overview for the currently supported profile.
class AccountOverview extends StatelessWidget {
  /// Creates the overview.
  const AccountOverview({
    required this.customer,
    required this.state,
    super.key,
  });

  /// Server-proven customer.
  final Customer customer;

  /// Session state, including sign-out progress and failure.
  final AccountState state;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: MediaQuery.sizeOf(context).width >= 1024
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 240,
                                child: AccountNavigation(state: state),
                              ),
                              Expanded(
                                child: AccountProfileOverview(
                                  customer: customer,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MobileAccountNavigation(
                                customer: customer,
                                state: state,
                              ),
                              const SizedBox(height: 32),
                              AccountProfileOverview(customer: customer),
                            ],
                          ),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: AccountSupport(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
