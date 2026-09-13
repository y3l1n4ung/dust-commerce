import 'package:commerce_server/src/features/admin/extractor.dart';
import 'package:commerce_server/src/features/admin_sales_channel/deps.dart';
import 'package:commerce_server/src/features/admin_sales_channel/model.dart';
import 'package:commerce_server/src/features/admin_sales_channel/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `GET /admin/sales-channels` — lists choices for a proven merchant.
Future<Result<AdminSalesChannelListResponse, Rejection>>
    listAdminSalesChannelsHandler(Request request) async {
  final actor = await const Extension<AuthenticatedAdmin>().extract(request);
  if (actor case Err(:final error)) return Err(error);
  final state = await adminSalesChannelDeps(request);
  if (state case Err(:final error)) return Err(error);
  final query = request.requestedUri.queryParameters;
  final limit = int.tryParse(query['limit'] ?? '') ?? defaultLimit;
  final offset = int.tryParse(query['offset'] ?? '') ?? 0;
  final deps = (state as Ok<AdminSalesChannelDeps, Rejection>).value;
  final result = await listAdminSalesChannels(
    deps.salesChannels,
    query: query['q'] ?? '',
    limit: limit.clamp(1, 1000),
    offset: offset < 0 ? 0 : offset,
  );
  return switch (result) {
    Ok(:final value) => Ok(value),
    Err() => const Err(Rejection.internal()),
  };
}
