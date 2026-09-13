part of 'admin_gate.dart';

/// Owns authenticated route transitions separately from shell composition.
mixin _AdminHomeActions on State<_AdminHome> {
  FocusNode get _orderSearchFocus;
  FocusNode get _optionSearchFocus;
  _AdminRoute get _route;
  set _route(_AdminRoute value);
  FocusNode get _searchFocus;
  String get _selectedId;
  set _selectedId(String value);
  FocusNode get _typeSearchFocus;
  FocusNode get _profileSearchFocus;

  String get selectedIdForNavigation => _selectedId;

  void _requestSearch() {
    if (_route == _AdminRoute.orders || _route == _AdminRoute.order) {
      _showOrders();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _orderSearchFocus.requestFocus();
      });
      return;
    }
    if (_route == _AdminRoute.productTypes ||
        _route == _AdminRoute.productType) {
      _showProductTypes();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _typeSearchFocus.requestFocus();
      });
      return;
    }
    if (_route == _AdminRoute.shippingProfiles ||
        _route == _AdminRoute.shippingProfile) {
      _showShippingProfiles();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _profileSearchFocus.requestFocus();
      });
      return;
    }
    final options = _route == _AdminRoute.productOptions ||
        _route == _AdminRoute.productOption;
    options ? _showProductOptions() : _showProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        (options ? _optionSearchFocus : _searchFocus).requestFocus();
      }
    });
  }

  void _showOrder(String id) => setState(() {
        _route = _AdminRoute.order;
        _selectedId = id;
      });

  void _showOrders() {
    context.readAdminOrderViewModel()
      ..load(offset: 0)
      ..loadFilterOptions();
    setState(() {
      _route = _AdminRoute.orders;
      _selectedId = '';
    });
  }

  void _showProducts() => setState(() {
        _route = _AdminRoute.products;
        _selectedId = '';
      });

  void _showProduct(String id) => setState(() {
        _route = _AdminRoute.product;
        _selectedId = id;
      });

  void _showProductOptions() {
    context.readAdminProductOptionViewModel().load(offset: 0);
    setState(() {
      _route = _AdminRoute.productOptions;
      _selectedId = '';
    });
  }

  void _showProductOption(String id) => setState(() {
        _route = _AdminRoute.productOption;
        _selectedId = id;
      });

  void _showProductTypes() {
    context.readAdminProductTypeViewModel().load(offset: 0);
    setState(() {
      _route = _AdminRoute.productTypes;
      _selectedId = '';
    });
  }

  void _showProductType(String id) => setState(() {
        _route = _AdminRoute.productType;
        _selectedId = id;
      });

  void _showShippingProfiles() {
    context.readAdminShippingProfileViewModel().load(offset: 0);
    setState(() {
      _route = _AdminRoute.shippingProfiles;
      _selectedId = '';
    });
  }

  void _showShippingProfile(String id) => setState(() {
        _route = _AdminRoute.shippingProfile;
        _selectedId = id;
      });

  Future<void> _createProduct() async {
    final created = await showAdminProductCreatePage(context);
    if (!mounted) return;
    if (created case Some(value: final product)) {
      await context.readAdminProductViewModel().load(offset: 0);
      if (mounted) _showProduct(product.id);
    }
  }

  Future<void> _createProductOption() async {
    final created = await showAdminProductOptionCreatePage(context);
    if (!mounted || created == null) return;
    _showProductOption(created.id);
  }
}
