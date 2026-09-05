import 'dart:async';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_app/route.dart';
import 'package:flutter/material.dart';

/// Connects one typed route to the shared product-listing state machine.
class ProductListingRoute extends StatefulWidget {
  /// Creates a route-owned listing request.
  const ProductListingRoute({
    required this.requestKey,
    required this.load,
    required this.onSortChanged,
    required this.onPageChanged,
    required this.onCategorySelected,
    super.key,
  });

  /// Category breadcrumb and child navigation.
  final ValueChanged<String> onCategorySelected;

  /// Runs the exact store, collection, or category request.
  final Future<void> Function(ProductListingViewModel viewModel) load;

  /// Changes the route page query.
  final ValueChanged<int> onPageChanged;

  /// Changes the route sort query.
  final ValueChanged<String> onSortChanged;

  /// Route/query identity used to reject state from the previous page.
  final String requestKey;

  @override
  State<ProductListingRoute> createState() => _ProductListingRouteState();
}

class _ProductListingRouteState extends State<ProductListingRoute> {
  @override
  void initState() {
    super.initState();
    _loadAfterFrame();
  }

  void _loadAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  Future<void> _load() async {
    final viewModel = context.readProductListingViewModel();
    await widget.load(viewModel);
    if (!mounted || viewModel.state.requestKey != widget.requestKey) return;
    if (viewModel.state.status == ProductListingStatus.missing) {
      context.navigator.notFound().replace();
    }
  }

  @override
  Widget build(BuildContext context) => StoreScaffold(
        body: ProductListingView(
          state: context.watchProductListingViewModel().value,
          requestKey: widget.requestKey,
          onRetry: _loadAfterFrame,
          onSortChanged: widget.onSortChanged,
          onPageChanged: widget.onPageChanged,
          onCategorySelected: widget.onCategorySelected,
        ),
      );
}
