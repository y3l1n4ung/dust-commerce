import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:flutter/material.dart';

import 'account_profile_overview.dart';
import 'account_route_layout.dart';
import 'account_section.dart';

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
  Widget build(BuildContext context) => AccountRouteLayout(
        customer: customer,
        state: state,
        active: AccountSection.overview,
        child: AccountProfileOverview(customer: customer),
      );
}
