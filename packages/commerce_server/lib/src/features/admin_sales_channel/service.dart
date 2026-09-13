import 'package:commerce_server/src/features/admin_sales_channel/model.dart';
import 'package:commerce_server/src/features/admin_sales_channel/repository.dart';
import 'package:dust_dart/db.dart';

/// Lists one bounded page of merchant-visible sales-channel choices.
Future<Result<AdminSalesChannelListResponse, SqlxError>> listAdminSalesChannels(
  AdminSalesChannelRepository salesChannels, {
  required String query,
  required int limit,
  required int offset,
}) async {
  final normalized = query.trim();
  final rows = await salesChannels.list(normalized, limit, offset);
  if (rows case Err(:final error)) return Err(error);
  final count = await salesChannels.count(normalized);
  if (count case Err(:final error)) return Err(error);
  return Ok(AdminSalesChannelListResponse(
    salesChannels:
        (rows as Ok<List<AdminSalesChannelResponse>, SqlxError>).value,
    count: (count as Ok<int, SqlxError>).value,
    limit: limit,
    offset: offset,
  ));
}
