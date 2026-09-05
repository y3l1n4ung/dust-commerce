import 'package:commerce_shared/commerce_shared.dart';

/// One field that failed, named the way the client sent it.
typedef FieldFailure = ({String field, String message});

/// Validates a checkout request and everything nested inside it.
///
/// Dust's generated `validate()` checks the fields of the class it is on and
/// stops there: `AddressInput` has its own generated validators, but
/// `CheckoutRequest.validate()` does not call them, so an address with an
/// empty recipient passes the outer check. Without this, a request missing a
/// name is accepted and the failure surfaces as an unshippable order.
///
/// Nested failures are prefixed with the field that holds them, so a client
/// gets `shipping_address.first_name` and can put the message next to the box
/// the person typed in.
List<FieldFailure> validateCheckout(CheckoutRequest request) {
  final failures = <FieldFailure>[
    for (final error in request.validate().errors)
      (field: error.field, message: error.message),
  ];

  failures.addAll(
    _nested('shipping_address', request.shippingAddress),
  );

  final billing = request.billingAddress;
  if (billing != null) {
    failures.addAll(_nested('billing_address', billing));
  }

  return failures;
}

List<FieldFailure> _nested(String prefix, AddressInput address) => [
      for (final error in address.validate().errors)
        (field: '$prefix.${error.field}', message: error.message),
    ];
