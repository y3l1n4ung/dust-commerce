import 'package:dust_server/server.dart';

/// The clock and the identifier source a handler is given.
///
/// Wrapped in a class so they travel as state like everything else. A handler
/// that reached for `DateTime.now()` directly could not be tested against a
/// fixed instant, and one that generated its own ids could not be asserted on.
final class Clock {
  /// Creates a [Clock].
  const Clock({required this.now, required this.nextId});

  /// The next identifier to hand out.
  final String Function() nextId;

  /// The current instant.
  final DateTime Function() now;
}

/// Reads state of type [T], or the 500 that says it was never attached.
///
/// A thin name over `StateExtractable`, so a handler reads
/// `await stateOf<NoteRepo>(request)` rather than constructing an extractor
/// inline every time.
Future<Result<T, Rejection>> stateOf<T extends Object>(Request request) =>
    StateExtractable<T>().extract(request);
