import 'package:admin_app/src/customer_group/admin_customer_group_api.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_create_view_model.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_delete_view_model.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_detail_view_model.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_edit_view_model.dart';
import 'package:admin_app/src/customer_group/admin_customer_group_view_model.dart';
import 'package:dio/dio.dart';

/// Customer-group API and state sharing the authenticated Admin Dio client.
final class AdminCustomerGroupDependencies {
  /// Creates the customer-group feature graph.
  factory AdminCustomerGroupDependencies(Dio dio, String baseUrl) {
    final api = AdminCustomerGroupApi(dio, baseUrl: baseUrl);
    return AdminCustomerGroupDependencies._(
      create: AdminCustomerGroupCreateViewModel(
        AdminCustomerGroupCreateViewModelArgs(api: api),
      ),
      detail: AdminCustomerGroupDetailViewModel(
        AdminCustomerGroupDetailViewModelArgs(api: api),
      ),
      delete: AdminCustomerGroupDeleteViewModel(
        AdminCustomerGroupDeleteViewModelArgs(api: api),
      ),
      edit: AdminCustomerGroupEditViewModel(
        AdminCustomerGroupEditViewModelArgs(api: api),
      ),
      list: AdminCustomerGroupViewModel(
        AdminCustomerGroupViewModelArgs(api: api),
      ),
    );
  }

  const AdminCustomerGroupDependencies._({
    required this.create,
    required this.detail,
    required this.delete,
    required this.edit,
    required this.list,
  });

  /// Focused customer-group creation state.
  final AdminCustomerGroupCreateViewModel create;

  /// Selected customer-group detail and member-table state.
  final AdminCustomerGroupDetailViewModel detail;

  /// Focused customer-group deletion command state.
  final AdminCustomerGroupDeleteViewModel delete;

  /// Focused customer-group edit command state.
  final AdminCustomerGroupEditViewModel edit;

  /// Customer-group collection state.
  final AdminCustomerGroupViewModel list;
}
