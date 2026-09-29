import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

/// Logs every bloc's lifecycle, events and errors in one place.
///
/// Only type names, never states or events themselves: they can carry
/// personal data, and each bloc logs its own meaningful steps. Release web
/// builds minify type names, so there only errors are logged.
final class AppBlocObserver extends BlocObserver {
  static final Logger _log = Logger('Bloc');

  static const bool _names = !kReleaseMode;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (_names) _log.finer('${bloc.runtimeType} created');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (_names) _log.fine('${bloc.runtimeType} ← ${event.runtimeType}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _log.severe(
      _names ? '${bloc.runtimeType} failed' : 'A bloc failed',
      error,
      stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (_names) _log.finer('${bloc.runtimeType} closed');
  }
}
