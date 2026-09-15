import 'dart:async';

import 'package:commerce_app/commerce_app.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:country_flags/country_flags.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/i18n.dart';
import 'package:flutter/material.dart';

/// Source-shaped country control shown at the bottom of the store menu.
final class StoreCountrySelect extends StatelessWidget {
  /// Creates the shared selling-country selector.
  const StoreCountrySelect({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watchStoreShellViewModel().value;
    final selected = shell.selectedCountryCode;
    if (selected case None()) return const SizedBox.shrink();
    final options = {
      for (final region in shell.regions)
        for (final country in region.countries) country,
    }.toList()
      ..sort((a, b) => countryName(context, a).compareTo(
            countryName(context, b),
          ));
    final code = (selected as Some<String>).value;
    final cart = context.watchCartViewModel().value;
    final changing = cart.operation == CartOperation.region &&
        cart.status == CartStatus.loading;

    return PopupMenuButton<String>(
      enabled: !changing,
      color: Colors.white,
      onSelected: (country) => unawaited(_change(context, country)),
      itemBuilder: (context) => [
        for (final country in options)
          PopupMenuItem(
            value: country,
            child: Row(
              children: [
                _StoreCountryFlag(countryCode: country),
                const SizedBox(width: 8),
                Text(countryName(context, country)),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              context.tr('shop_shipping_to', defaultText: 'Shipping to:'),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 8),
            _StoreCountryFlag(countryCode: code),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                countryName(context, code),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _change(BuildContext context, String countryCode) async {
    final shell = context.readStoreShellViewModel();
    final target = shell.state.regionForCountry(countryCode);
    if (target case None()) return;
    final region = (target as Some<Region>).value;
    final changed = await context.readCartViewModel().changeRegion(region.id);
    if (!context.mounted) return;
    if (!changed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr(
          'shop_country_change_failed',
          defaultText: 'Could not change shipping country.',
        )),
      ));
      return;
    }
    final selected = await shell.selectCountry(countryCode);
    if (selected && context.mounted) Navigator.of(context).pop();
  }
}

final class _StoreCountryFlag extends StatelessWidget {
  const _StoreCountryFlag({required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) => CountryFlag.fromCountryCode(
        countryCode,
        theme: const ImageTheme(width: 16, height: 16),
      );
}
