import 'package:commerce_shared/commerce_shared.dart';
import 'package:test/test.dart';

void main() {
  ProductVariant variant(String id, String size, {int stock = 3}) =>
      ProductVariant.of(
        id: id,
        title: '$size / Black',
        prices: [Money.of(1999, 'usd')],
        inventoryQuantity: stock,
        optionValues: {'opt_size': size},
      );

  Product product({
    ProductStatus status = ProductStatus.published,
    List<ProductVariant>? variants,
  }) =>
      Product.of(
        id: 'prod_1',
        title: 'T-Shirt',
        handle: 'T-Shirt',
        status: status,
        options: [
          ProductOption.of(
            id: 'opt_size',
            title: 'Size',
            values: const ['Small', 'Large'],
          ),
        ],
        variants: variants ??
            [variant('v_small', 'Small'), variant('v_large', 'Large')],
      );

  group('Product.of', () {
    test('slugifies the handle, which is what the storefront routes on', () {
      expect(Product.of(id: 'p', title: 'T', handle: 'Blue T-Shirt!').handle,
          'blue-t-shirt');
    });

    test('rejects two variants sharing an id', () {
      expect(
        () => product(
          variants: [variant('v_dup', 'Small'), variant('v_dup', 'Large')],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a variant whose option value the product does not offer', () {
      expect(
        () => product(variants: [variant('v_xl', 'Extra Large')]),
        throwsArgumentError,
      );
    });

    test('allows a product with no variants, which is a draft', () {
      expect(Product.of(id: 'p', title: 'T', handle: 't').variants, isEmpty);
    });
  });

  group('purchasability', () {
    test('is purchasable when published with a variant in stock', () {
      expect(product().isPurchasable, isTrue);
    });

    test('is not purchasable while a draft, whatever the stock says', () {
      expect(product(status: ProductStatus.draft).isPurchasable, isFalse);
    });

    test('is not purchasable when every variant is out of stock', () {
      final sold = product(variants: [variant('v_small', 'Small', stock: 0)]);

      expect(sold.isPurchasable, isFalse);
    });
  });

  group('variant lookup', () {
    test('finds a variant by its option values', () {
      final found = product().variantFor(const {'opt_size': 'Large'});

      expect(found?.id, 'v_large');
    });

    test('returns null when no variant matches', () {
      expect(product().variantFor(const {'opt_size': 'Tiny'}), isNull);
    });

    test('finds a variant by id', () {
      expect(product().variantById('v_small')?.title, 'Small / Black');
      expect(product().variantById('nope'), isNull);
    });
  });

  group('pricing', () {
    test('reports the cheapest price in a currency', () {
      expect(product().cheapestIn('usd'), Money.of(1999, 'usd'));
      expect(product().cheapestIn('gbp'), isNull);
    });
  });

  group('json', () {
    test('round-trips through the generated codec', () {
      final subject = product();

      expect(Product.fromJson(subject.toJson()), subject);
    });

    test('encodes status as its wire name', () {
      expect(product().toJson()['status'], 'published');
    });
  });
}
