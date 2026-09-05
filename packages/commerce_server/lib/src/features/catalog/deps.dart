import 'package:commerce_server/src/features/catalog/repository/repository.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// Everything the catalogue handlers need, attached once with `withState`.
final class CatalogDeps {
  /// Creates a [CatalogDeps].
  const CatalogDeps({required this.reads, required this.lists});

  /// The list queries.
  final CatalogListRepository lists;

  /// The single-row reads.
  final CatalogReadRepository reads;
}

/// The catalogue dependencies, or the 500 that says they were never attached.
Future<Result<CatalogDeps, Rejection>> catalogDeps(Request request) =>
    stateOf<CatalogDeps>(request);
