import 'package:commerce_shared/commerce_shared.dart';
import 'package:test/test.dart';

void main() {
  Region europe({int taxRate = 2000, bool taxInclusive = false}) => Region.of(
        id: 'reg_eu',
        name: 'Europe',
        currencyCode: 'EUR',
        taxRate: taxRate,
        countries: const ['de', 'FR'],
        taxInclusive: taxInclusive,
      );

  group('Region.of', () {
    test('normalises the currency and country codes to lower case', () {
      final region = europe();

      expect(region.currencyCode, 'eur');
      expect(region.countries, ['de', 'fr']);
    });

    test('rejects a tax rate outside nought to one hundred per cent', () {
      expect(() => europe(taxRate: -1), throwsArgumentError);
      expect(() => europe(taxRate: 10001), throwsArgumentError);
    });

    test('accepts the boundaries of the tax rate', () {
      expect(europe(taxRate: 0).taxRate, 0);
      expect(europe(taxRate: 10000).taxRate, 10000);
    });

    test('rejects a country code that is not two letters', () {
      expect(
        () => Region.of(
          id: 'reg_x',
          name: 'X',
          currencyCode: 'usd',
          taxRate: 0,
          countries: const ['deu'],
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty country list, which would serve nobody', () {
      expect(
        () => Region.of(
          id: 'reg_x',
          name: 'X',
          currencyCode: 'usd',
          taxRate: 0,
          countries: const [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('tax', () {
    test('adds tax on top when the region is tax exclusive', () {
      final region = europe(taxRate: 2000);

      expect(region.taxOn(Money.of(1000, 'eur')), Money.of(200, 'eur'));
      expect(region.withTax(Money.of(1000, 'eur')), Money.of(1200, 'eur'));
    });

    test('takes tax out of the price when the region is tax inclusive', () {
      final region = europe(taxRate: 2000, taxInclusive: true);

      expect(region.taxOn(Money.of(1200, 'eur')), Money.of(200, 'eur'));
      expect(region.withTax(Money.of(1200, 'eur')), Money.of(1200, 'eur'));
    });

    test('refuses an amount in another currency', () {
      expect(
        () => europe().taxOn(Money.of(1000, 'usd')),
        throwsArgumentError,
      );
    });

    test('rounds a fractional minor unit half up', () {
      final region = europe(taxRate: 875);

      expect(region.taxOn(Money.of(1999, 'eur')), Money.of(175, 'eur'));
    });
  });

  group('membership', () {
    test('knows which countries it serves, case insensitively', () {
      expect(europe().serves('DE'), isTrue);
      expect(europe().serves('fr'), isTrue);
      expect(europe().serves('us'), isFalse);
    });
  });

  group('json', () {
    test('round-trips through the generated codec', () {
      final region = europe();

      expect(Region.fromJson(region.toJson()), region);
    });
  });
}
