part of 'admin_gate.dart';

/// Keeps route transitions out of the authenticated shell composition.
mixin _AdminHomeNavigation on State<_AdminHome> {
  FocusNode get _orderSearchFocus;
  FocusNode get _optionSearchFocus;
  _AdminRoute get _route;
  set _route(_AdminRoute value);
  FocusNode get _searchFocus;
  String get _selectedId;
  set _selectedId(String value);
  FocusNode get _typeSearchFocus;

  Widget buildAdminHome(BuildContext context) {
    final optionDetail =
        context.watchAdminProductOptionDetailViewModel().value.productOption;
    final typeDetail =
        context.watchAdminProductTypeDetailViewModel().value.productType;
    return AdminShell(
      user: widget.user,
      themes: widget.themes,
      title: switch (_route) {
        _AdminRoute.orders => 'Orders',
        _AdminRoute.products => 'Products',
        _AdminRoute.product => 'Product details',
        _AdminRoute.productOptions => 'Options',
        _AdminRoute.productOption => switch (optionDetail) {
            Some(value: final option) => 'Options  ›  ${option.title}',
            None() => 'Options',
          },
        _AdminRoute.productTypes => 'Settings  ›  Product Types',
        _AdminRoute.productType => switch (typeDetail) {
            Some(value: final type) => 'Product Types  ›  ${type.value}',
            None() => 'Product Types',
          },
      },
      onSearchRequested: _requestSearch,
      onOrdersRequested: _showOrders,
      onProductsRequested: _showProducts,
      onProductOptionsRequested: _showProductOptions,
      onProductTypesRequested: _showProductTypes,
      selectedSection: switch (_route) {
        _AdminRoute.orders => AdminShellSection.orders,
        _AdminRoute.products ||
        _AdminRoute.product =>
          AdminShellSection.products,
        _AdminRoute.productOptions ||
        _AdminRoute.productOption =>
          AdminShellSection.productOptions,
        _AdminRoute.productTypes ||
        _AdminRoute.productType =>
          AdminShellSection.productTypes,
      },
      onSignOut: widget.state.isBusy
          ? null
          : context.readAdminSessionViewModel().signOut,
      child: switch (_route) {
        _AdminRoute.orders => AdminOrderPage(searchFocus: _orderSearchFocus),
        _AdminRoute.product => AdminProductDetailPage(
            productId: _selectedId,
            onBack: _showProducts,
            onOpenOption: _showProductOption,
          ),
        _AdminRoute.products => AdminProductPage(
            searchFocus: _searchFocus,
            onCreateProduct: _createProduct,
            onOpenProduct: _showProduct,
          ),
        _AdminRoute.productOptions => AdminProductOptionPage(
            searchFocus: _optionSearchFocus,
            onOpen: _showProductOption,
            onCreate: _createProductOption,
          ),
        _AdminRoute.productOption => AdminProductOptionDetailPage(
            productOptionId: _selectedId,
            onBack: _showProductOptions,
            onOpenProduct: _showProduct,
          ),
        _AdminRoute.productTypes => AdminProductTypePage(
            searchFocus: _typeSearchFocus,
            onOpen: _showProductType,
          ),
        _AdminRoute.productType => AdminProductTypeDetailPage(
            productTypeId: _selectedId,
            onBack: _showProductTypes,
            onOpenProduct: _showProduct,
          ),
      },
    );
  }

  void _requestSearch() {
    if (_route == _AdminRoute.orders) {
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
    final options = _route == _AdminRoute.productOptions ||
        _route == _AdminRoute.productOption;
    options ? _showProductOptions() : _showProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        (options ? _optionSearchFocus : _searchFocus).requestFocus();
      }
    });
  }

  void _showProducts() => setState(() {
        _route = _AdminRoute.products;
        _selectedId = '';
      });

  void _showOrders() {
    context.readAdminOrderViewModel().load(offset: 0);
    setState(() {
      _route = _AdminRoute.orders;
      _selectedId = '';
    });
  }

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
