part of 'commerce_app.dart';

Widget _storefrontScopes({
  required CommerceApi api,
  required AccountViewModel account,
  required AddressBookViewModel addresses,
  required AccountOrderDetailViewModel orderDetail,
  required AccountOrdersViewModel orders,
  required OrderTransferViewModel orderTransfer,
  required CartViewModel cart,
  required CheckoutViewModel checkout,
  required StoreShellViewModel shell,
  required Widget child,
}) =>
    AccountViewModelScope.value(
      value: account,
      child: AddressBookViewModelScope.value(
        value: addresses,
        child: AccountOrderDetailViewModelScope.value(
          value: orderDetail,
          child: AccountOrdersViewModelScope.value(
            value: orders,
            child: OrderTransferViewModelScope.value(
              value: orderTransfer,
              child: CartViewModelScope.value(
                value: cart,
                child: CheckoutViewModelScope.value(
                  value: checkout,
                  child: ProductViewModelScope(
                    args: (_) => ProductViewModelArgs(api: api),
                    create: (_, args) => ProductViewModel(args),
                    child: CatalogViewModelScope(
                      args: (_) => CatalogViewModelArgs(api: api),
                      create: (_, args) => CatalogViewModel(args),
                      child: ProductListingViewModelScope(
                        args: (_) => ProductListingViewModelArgs(api: api),
                        create: (_, args) => ProductListingViewModel(args),
                        child: StoreShellViewModelScope.value(
                          value: shell,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
