part of 'admin_gate.dart';

/// Keeps route transitions out of the authenticated shell composition.
mixin _AdminHomeNavigation on State<_AdminHome>, _AdminHomeActions {
  Widget buildAdminHome(BuildContext context) {
    final optionDetail =
        context.watchAdminProductOptionDetailViewModel().value.productOption;
    final orderDetail = context.watchAdminOrderDetailViewModel().value.order;
    final typeDetail =
        context.watchAdminProductTypeDetailViewModel().value.productType;
    return AdminShell(
      user: widget.user,
      themes: widget.themes,
      title: switch (_route) {
        _AdminRoute.orders => 'Orders',
        _AdminRoute.order => switch (orderDetail) {
            Some(value: final order) => 'Orders  ›  #${order.displayId}',
            None() => 'Orders',
          },
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
        _AdminRoute.orders || _AdminRoute.order => AdminShellSection.orders,
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
        _AdminRoute.orders => AdminOrderPage(
            searchFocus: _orderSearchFocus,
            onOpen: _showOrder,
          ),
        _AdminRoute.order => AdminOrderDetailPage(
            orderId: selectedIdForNavigation,
            onBack: _showOrders,
          ),
        _AdminRoute.product => AdminProductDetailPage(
            productId: selectedIdForNavigation,
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
            productOptionId: selectedIdForNavigation,
            onBack: _showProductOptions,
            onOpenProduct: _showProduct,
          ),
        _AdminRoute.productTypes => AdminProductTypePage(
            searchFocus: _typeSearchFocus,
            onOpen: _showProductType,
          ),
        _AdminRoute.productType => AdminProductTypeDetailPage(
            productTypeId: selectedIdForNavigation,
            onBack: _showProductTypes,
            onOpenProduct: _showProduct,
          ),
      },
    );
  }
}
