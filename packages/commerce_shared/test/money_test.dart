import 'package:commerce_shared/commerce_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Money.of', () {
    test('normalises the currency code to lower case', () {
      expect(Money.of(1000, 'USD').currencyCode, 'usd');
    });

    test('rejects a code that is not three letters', () {
      expect(() => Money.of(1, 'US'), throwsArgumentError);
      expect(() => Money.of(1, 'USDD'), throwsArgumentError);
      expect(() => Money.of(1, 'US1'), throwsArgumentError);
      expect(() => Money.of(1, ''), throwsArgumentError);
    });

    test('allows a negative amount, which a discount needs', () {
      expect(Money.of(-500, 'usd').amount, -500);
    });
  });

  group('arithmetic', () {
    test('adds two amounts in the same currency', () {
      expect(
          Money.of(1000, 'usd') + Money.of(250, 'usd'), Money.of(1250, 'usd'));
    });

    test('subtracts two amounts in the same currency', () {
      expect(
          Money.of(1000, 'usd') - Money.of(250, 'usd'), Money.of(750, 'usd'));
    });

    test('multiplies by a quantity', () {
      expect(Money.of(1250, 'usd') * 3, Money.of(3750, 'usd'));
    });

    test('refuses to mix currencies', () {
      final usd = Money.of(1000, 'usd');
      final eur = Money.of(1000, 'eur');

      expect(() => usd + eur, throwsArgumentError);
      expect(() => usd - eur, throwsArgumentError);
    });
  });

  group('comparison', () {
    test('orders amounts in the same currency', () {
      expect(Money.of(1000, 'usd') > Money.of(999, 'usd'), isTrue);
      expect(Money.of(1000, 'usd') < Money.of(999, 'usd'), isFalse);
      expect(Money.of(1000, 'usd') >= Money.of(1000, 'usd'), isTrue);
      expect(Money.of(999, 'usd') <= Money.of(1000, 'usd'), isTrue);
    });

    test('refuses to compare across currencies', () {
      expect(
          () => Money.of(1, 'usd') > Money.of(1, 'eur'), throwsArgumentError);
    });

    test('is equal by value, not identity', () {
      expect(Money.of(1000, 'usd'), Money.of(1000, 'usd'));
      expect(Money.of(1000, 'usd'), isNot(Money.of(1000, 'eur')));
      expect(Money.of(1000, 'usd').hashCode, Money.of(1000, 'usd').hashCode);
    });
  });

  group('zero', () {
    test('is the additive identity for its currency', () {
      final zero = Money.zero('usd');

      expect(zero.amount, 0);
      expect(Money.of(1000, 'usd') + zero, Money.of(1000, 'usd'));
      expect(zero.isZero, isTrue);
    });
  });

  group('json', () {
    test('round-trips through the generated codec', () {
      final money = Money.of(1999, 'usd');

      expect(Money.fromJson(money.toJson()), money);
    });

    test('carries the amount as an integer, never a decimal', () {
      expect(Money.of(1999, 'usd').toJson()['amount'], 1999);
      expect(Money.of(1999, 'usd').toJson()['amount'], isA<int>());
    });
  });
}
