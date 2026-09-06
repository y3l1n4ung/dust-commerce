import 'package:commerce_app/src/core/api/api.dart';
import 'package:commerce_app/src/core/storage/storage.dart';
import 'package:commerce_app/src/features/shell/model/store_shell_state.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:dust_flutter/state.dart';

part 'store_shell_view_model.g.dart';

/// Dependencies for taxonomy shared by every main-store route.
final class StoreShellViewModelArgs extends ViewModelArgs {
  /// Creates shell dependencies.
  const StoreShellViewModelArgs({
    required this.api,
    required this.countries,
    super.observer,
  });

  /// Store API used for public navigation discovery.
  final CommerceApi api;

  /// Persisted storefront-country preference.
  final CountryPreferenceStore countries;
}

/// Loads the footer taxonomy once without making page content depend on it.
@ViewModel(state: StoreShellState, args: StoreShellViewModelArgs)
class StoreShellViewModel extends $StoreShellViewModel {
  /// Creates the shared shell state machine.
  StoreShellViewModel(super.args);

  /// Loads independent collection and category inventories concurrently.
  Future<void> load() async {
    if (state.status == StoreShellStatus.loading) return;
    emit(state.copyWith(status: StoreShellStatus.loading));
    final collections = _collections();
    final categories = _categories();
    final regions = _regions();
    final preferred = _preferredCountry();
    final loadedRegions = await regions;
    emit(StoreShellState(
      status: StoreShellStatus.ready,
      collections: await collections,
      categories: await categories,
      regions: loadedRegions,
      selectedCountryCode: _initialCountry(
        loadedRegions,
        await preferred,
      ),
    ));
  }

  /// Selects and persists a country served by an active region.
  Future<bool> selectCountry(String countryCode) async {
    final normalized = countryCode.trim().toLowerCase();
    if (state.regionForCountry(normalized) case None()) return false;
    emit(state.copyWith(selectedCountryCode: Some(normalized)));
    try {
      await args.countries.write(normalized);
    } on Object {
      // A storage outage must not undo a successful cart and UI transition.
    }
    return true;
  }

  Future<List<ProductCollection>> _collections() async {
    try {
      return (await args.api.collections(limit: 100)).collections;
    } on Exception {
      // Footer discovery never replaces working page content with an error.
      return const [];
    }
  }

  Future<List<ProductCategory>> _categories() async {
    try {
      return (await args.api.categories(limit: 100)).categories;
    } on Exception {
      // Each column fails independently, matching the optional source blocks.
      return const [];
    }
  }

  Future<List<Region>> _regions() async {
    try {
      return (await args.api.regions()).regions;
    } on Exception {
      return const [];
    }
  }

  Future<Option<String>> _preferredCountry() async {
    try {
      return await args.countries.read();
    } on Object {
      return const None();
    }
  }

  static Option<String> _initialCountry(
    List<Region> regions,
    Option<String> preferred,
  ) {
    final saved = preferred.match(
      some: (country) => country,
      none: () => '',
    );
    if (saved.isNotEmpty && regions.any((region) => region.serves(saved))) {
      return Some(saved);
    }
    if (regions.any((region) => region.serves('dk'))) {
      return const Some('dk');
    }
    for (final region in regions) {
      if (region.countries.isNotEmpty) return Some(region.countries.first);
    }
    return const None();
  }
}
