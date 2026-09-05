import 'dart:async';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

import 'account_navigation.dart';
import 'account_order_card.dart';

/// Authenticated Medusa order-history route.
@AppRoute('/account/orders', name: 'accountOrders', guards: [CustomerGuard])
class AccountOrdersPage extends StatefulWidget {
  /// Creates the order-history page.
  const AccountOrdersPage({super.key});

  @override
  State<AccountOrdersPage> createState() => _AccountOrdersPageState();
}

class _AccountOrdersPageState extends State<AccountOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.readAccountOrdersViewModel().load());
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watchAccountViewModel().value;
    final orders = context.watchAccountOrdersViewModel().value;
    final customer = account.customer;
    return StoreScaffold(
      body: customer == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1024),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 48,
                    ),
                    child: MediaQuery.sizeOf(context).width >= 1024
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 240,
                                child: AccountNavigation(
                                  state: account,
                                  ordersActive: true,
                                ),
                              ),
                              Expanded(child: _OrdersContent(state: orders)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MobileAccountNavigation(
                                customer: customer,
                                state: account,
                              ),
                              const SizedBox(height: 32),
                              _OrdersContent(state: orders),
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _OrdersContent extends StatelessWidget {
  const _OrdersContent({required this.state});

  final AccountOrdersState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TranslatedText(
            'shop_account_orders',
            defaultText: 'Orders',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const TranslatedText(
            'shop_account_orders_body',
            defaultText: 'View your previous orders and their status.',
          ),
          const SizedBox(height: 32),
          switch (state.status) {
            AccountOrdersStatus.idle ||
            AccountOrdersStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            AccountOrdersStatus.failed => Column(
                children: [
                  Text(state.message ?? 'Could not load your orders.'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: context.readAccountOrdersViewModel().load,
                    child: const TranslatedText(
                      'shop_retry',
                      defaultText: 'Try again',
                    ),
                  ),
                ],
              ),
            AccountOrdersStatus.ready when state.orders.isEmpty =>
              const _EmptyOrders(),
            AccountOrdersStatus.ready => Column(
                children: [
                  for (final order in state.orders) ...[
                    AccountOrderCard(order: order),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
          },
        ],
      );
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const TranslatedText(
            'shop_account_orders_empty_title',
            defaultText: 'Nothing to see here',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const TranslatedText(
            'shop_account_orders_empty_body',
            defaultText: "You don't have any orders yet, let us change that.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.navigator.catalog().go(),
            child: const TranslatedText(
              'shop_account_continue_shopping',
              defaultText: 'Continue shopping',
            ),
          ),
        ],
      );
}
