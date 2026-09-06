import 'package:commerce_server/src/features/account/crypto.dart';
import 'package:commerce_server/src/features/admin/repository/repository.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:commerce_server/src/infra/database.dart';
import 'package:dust_server/server.dart';

/// Dependencies used only by merchant-admin authentication.
final class AdminDeps {
  /// Creates the admin dependency bundle.
  const AdminDeps({
    required this.reads,
    required this.writes,
    required this.deletes,
    required this.clock,
    required this.passwordWork,
    required this.dummyPasswordHash,
    required this.products,
    required this.productReads,
    required this.database,
  });

  /// Shared identifier and time source.
  final Clock clock;

  /// Transaction boundary for product writes followed by detail reads.
  final CommerceDatabase database;

  /// Session-revocation queries.
  final AdminDeleteRepository deletes;

  /// Equal-cost hash for unknown-email authentication.
  final Future<String> dummyPasswordHash;

  /// Shared bound on memory-hard password work.
  final PasswordWorkLimiter passwordWork;

  /// Merchant catalogue listing queries.
  final AdminProductRepository products;

  /// Complete merchant product detail reads.
  final AdminProductReadRepository productReads;

  /// Admin credential and session reads.
  final AdminReadRepository reads;

  /// Admin profile, identity and session writes.
  final AdminCreateRepository writes;
}

/// The attached admin dependencies, or a configuration 500.
Future<Result<AdminDeps, Rejection>> adminDeps(Request request) =>
    stateOf<AdminDeps>(request);
