import 'package:dust_dart/db.dart';
import 'package:dust_dart/serde.dart';

part 'model.g.dart';

/// One Admin sales-channel choice populated directly from its final table.
@Derive([Serialize(), FromRow()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminSalesChannelResponse with _$AdminSalesChannelResponse {
  /// Creates the explicit merchant allowlist.
  const AdminSalesChannelResponse({required this.id, required this.name});

  /// Stable commercial-origin identifier.
  final String id;

  /// Merchant-facing sales-channel name.
  final String name;
}

/// One bounded page of explicit Admin sales-channel responses.
@Derive([Serialize()])
@SerDe(renameAll: SerDeRename.snakeCase)
final class AdminSalesChannelListResponse with _$AdminSalesChannelListResponse {
  /// Creates list metadata and direct SQLx rows.
  const AdminSalesChannelListResponse({
    required this.salesChannels,
    required this.count,
    required this.limit,
    required this.offset,
  });

  /// Total non-deleted rows matching the query.
  final int count;

  /// Maximum requested page size.
  final int limit;

  /// Number of matching rows skipped.
  final int offset;

  /// Explicit merchant sales-channel rows.
  final List<AdminSalesChannelResponse> salesChannels;
}
