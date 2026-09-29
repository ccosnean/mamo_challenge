import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('Errors');

/// Sends uncaught framework and async errors to the log (and so to every
/// sink, redacted), keeping any handler that was already installed.
void installErrorLogging() {
  final previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    // One short line; the full description travels once, as the error.
    _log.severe(
      'Flutter error${details.library == null ? '' : ' in ${details.library}'}',
      details.exceptionAsString(),
      details.stack,
    );
    previousFlutter?.call(details);
  };

  final previousPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    _log.severe('Uncaught', error, stackTrace);
    return previousPlatform?.call(error, stackTrace) ?? false;
  };
}
