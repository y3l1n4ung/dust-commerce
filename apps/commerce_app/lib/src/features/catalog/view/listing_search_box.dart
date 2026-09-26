import 'dart:async';

import 'package:commerce_app/src/core/store_theme.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Medusa Store search box backed by the product-listing route query.
final class ListingSearchBox extends StatefulWidget {
  /// Creates the search box.
  const ListingSearchBox({
    required this.query,
    required this.onChanged,
    super.key,
  });

  /// Current route query.
  final String query;

  /// Debounced query replacement.
  final ValueChanged<String> onChanged;

  @override
  State<ListingSearchBox> createState() => _ListingSearchBoxState();
}

final class _ListingSearchBoxState extends State<ListingSearchBox> {
  late final TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(ListingSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: StoreColors.foregroundMuted,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: context.tr(
                    'shop_search_clear',
                    defaultText: 'Clear search',
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clear,
                ),
          hintText: context.tr(
            'shop_search_products',
            defaultText: 'Search products',
          ),
          border: const UnderlineInputBorder(),
        ),
        onChanged: _changed,
      );

  void _changed(String value) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), () {
      widget.onChanged(value);
    });
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() {});
    widget.onChanged('');
  }
}
