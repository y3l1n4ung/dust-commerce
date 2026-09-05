import 'dart:convert';

import 'package:commerce_server/src/features/catalog/model.dart';
import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/infra/option.dart';
import 'package:dust_dart/db.dart';

/// Lists complete published product responses in [currencyCode].
Future<Result<ProductPageResponse, SqlxError>> listProducts(
  CatalogListRepository lists,
  CatalogCountRepository counts, {
  required String currencyCode,
  Option<String> collection = const None(),
  Option<String> category = const None(),
  Option<String> tag = const None(),
  List<String> optionValueIds = const [],
  int limit = 20,
  int offset = 0,
}) async {
  final page = await lists.listPublished(
    currencyCode,
    limit,
    offset,
    nullableOf(collection),
    nullableOf(category),
    nullableOf(tag),
    jsonEncode(optionValueIds),
  );
  if (page case Err(:final error)) return Err(error);

  final total = await counts.countPublished(
    nullableOf(collection),
    nullableOf(category),
    nullableOf(tag),
    jsonEncode(optionValueIds),
  );
  if (total case Err(:final error)) return Err(error);

  final products = (page as Ok<List<ProductResponse>, SqlxError>).value;
  return Ok(ProductPageResponse(
    products: products,
    count: products.length,
    total: (total as Ok<int, SqlxError>).value,
    limit: limit,
    offset: offset,
  ));
}
