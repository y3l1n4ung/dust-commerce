part of 'admin_gate.dart';

/// Owns the customer-group route transition and its shared navigation fields.
mixin _AdminCustomerGroupActions on State<_AdminHome> {
  FocusNode get _customerGroupSearchFocus;
  _AdminRoute get _route;
  set _route(_AdminRoute value);
  String get _selectedId;
  set _selectedId(String value);
  String get _selectedCustomerId;
  set _selectedCustomerId(String value);

  void _showCustomerGroups() {
    context.readAdminCustomerGroupViewModel().load(offset: 0);
    setState(() {
      _route = _AdminRoute.customerGroups;
      _selectedId = '';
      _selectedCustomerId = '';
    });
  }
}
