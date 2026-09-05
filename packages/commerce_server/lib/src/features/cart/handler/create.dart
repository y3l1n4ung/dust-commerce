import 'dart:convert';

import 'package:commerce_server/src/features/cart/repository/repository.dart';
import 'package:commerce_server/src/features/cart/service/service.dart';
import 'package:commerce_server/src/http/http.dart';
import 'package:dust_server/server.dart';

/// `POST /carts` — start an empty cart.
Handler createCartHandler(
  CartCreateRepository writes, {
  required String Function() nextId,
  required DateTime Function() now,
}) {
  return (Request request) async {
    // A body is optional: POST /carts with nothing starts a cart in the
    // default region, which is what a storefront does before it knows where
    // the customer is.
    String? regionId;
    final raw = await request.readAsString();
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, Object?>) {
          return badRequest('Expected a JSON object');
        }
        final asked = decoded['region_id'];
        if (asked != null && asked is! String) {
          return unprocessable('region_id must be a string');
        }
        regionId = asked as String?;
      } on FormatException {
        return badRequest('Expected a JSON object');
      }
    }

    final result = await createCart(
      writes,
      id: nextId(),
      now: now(),
      regionId: regionId,
    );

    return switch (result) {
      Ok(value: final cart?) => jsonResponse(cart.toJson(), status: 201),
      Ok() when regionId != null =>
        unprocessable('Region "$regionId" does not exist'),
      Ok() => errorResponse(
          503,
          code: 'no_region',
          message: 'The shop has no region configured',
        ),
      Err() => internalError(),
    };
  };
}
