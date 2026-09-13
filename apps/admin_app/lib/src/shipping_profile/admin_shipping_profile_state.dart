import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/derive.dart';

part 'admin_shipping_profile_state.g.dart';

/// Lifecycle of the shipping-profile settings table.
enum AdminShippingProfileStatus {
  /// No request has started.
  idle,

  /// A bounded profile page is loading.
  loading,

  /// The requested page is ready.
  ready,

  /// The request failed with display-safe copy.
  failed,
}

/// Immutable state for shipping-profile administration.
@Derive([ToString(), Eq(), CopyWith()])
final class AdminShippingProfileState with _$AdminShippingProfileState {
  /// Creates list state without transport objects in widgets.
  const AdminShippingProfileState({
    this.status = AdminShippingProfileStatus.idle,
    this.shippingProfiles = const [],
    this.count = 0,
    this.limit = 20,
    this.offset = 0,
    this.query = '',
    this.failure = const None(),
  });

  /// Total rows matching [query].
  final int count;

  /// Display-safe failure message.
  final Option<String> failure;

  /// Server-owned page size.
  final int limit;

  /// Number of matching rows skipped.
  final int offset;

  /// Current normalized name-or-type search.
  final String query;

  /// Current explicit fulfillment rows.
  final List<AdminShippingProfile> shippingProfiles;

  /// Current request lifecycle.
  final AdminShippingProfileStatus status;

  /// Whether another server page exists.
  bool get hasNext => offset + shippingProfiles.length < count;

  /// Whether a preceding server page exists.
  bool get hasPrevious => offset > 0;
}
