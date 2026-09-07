import 'package:dust_dart/fp.dart';

/// Product-list order values accepted by the Medusa-shaped Admin API.
enum AdminProductOrder {
  /// Product title A to Z.
  titleAsc('title'),

  /// Product title Z to A.
  titleDesc('-title'),

  /// Oldest products first.
  createdAtAsc('created_at'),

  /// Newest products first.
  createdAtDesc('-created_at'),

  /// Least recently updated products first.
  updatedAtAsc('updated_at'),

  /// Most recently updated products first.
  updatedAtDesc('-updated_at');

  const AdminProductOrder(this.parameter);

  /// Stable Admin API query value.
  final String parameter;

  /// Parses one allowlisted Admin API query value.
  static Option<AdminProductOrder> parse(String parameter) {
    for (final order in values) {
      if (order.parameter == parameter) return Some(order);
    }
    return const None();
  }
}
