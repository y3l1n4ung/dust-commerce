import 'package:commerce_server/src/features/region/model.dart';
import 'package:commerce_server/src/features/region/repository.dart';
import 'package:dust_dart/db.dart';

/// Lists active selling regions for storefront country selection.
Future<Result<SellingRegionListResponse, SqlxError>> listSellingRegions(
  SellingRegionRepository regions,
) async {
  final result = await regions.list();
  return switch (result) {
    Ok(:final value) => Ok(SellingRegionListResponse(
        regions: value,
        count: value.length,
      )),
    Err(:final error) => Err(error),
  };
}
