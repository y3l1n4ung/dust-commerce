import 'package:dust_server/server.dart';

/// The one JSON error shape every endpoint answers with.
///
/// A client that has to recognise several error shapes ends up parsing none of
/// them properly. `code` is for software, `message` is for a person, and both
/// are always present.
Response errorResponse(
  int status, {
  required String code,
  required String message,
}) {
  return jsonResponse(
    {
      'error': {'code': code, 'message': message},
    },
    status: status,
  );
}

/// 404, for a resource that does not exist or is not visible to this caller.
///
/// A draft product answers the same as a missing one on purpose: telling an
/// anonymous caller that a handle exists but is not theirs to see leaks the
/// catalogue before it launches.
Response notFound(String what) => errorResponse(
      404,
      code: 'not_found',
      message: '$what was not found',
    );

/// 422, for a request that parsed but does not make sense.
Response unprocessable(String message) => errorResponse(
      422,
      code: 'unprocessable',
      message: message,
    );

/// 400, for a request that does not parse.
Response badRequest(String message) => errorResponse(
      400,
      code: 'bad_request',
      message: message,
    );

/// 500, for a failure the caller can do nothing about.
///
/// The cause is deliberately not in the body. A database error message is for
/// the operator reading logs, not for whoever sent the request.
Response internalError() => errorResponse(
      500,
      code: 'internal',
      message: 'The server could not complete this request',
    );
