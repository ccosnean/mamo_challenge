import 'dart:async';

/// Holds a value and exposes it as a stream that replays the current value to
/// every new listener, then emits each change.
///
/// Useful for repositories that must let late subscribers (e.g. a bloc
/// created when a screen opens) see the current state without waiting for
/// the next change.
final class LatestValue<T> {
  LatestValue(this._value);

  T _value;
  final StreamController<T> _changes = StreamController<T>.broadcast();

  T get value => _value;

  /// After [close], updates are ignored: a request that finishes after its
  /// owner was disposed has nobody to tell.
  set value(T newValue) {
    if (_changes.isClosed) return;
    _value = newValue;
    _changes.add(newValue);
  }

  /// Emits [value] immediately on listen, then every subsequent change.
  Stream<T> get stream => Stream<T>.multi((listener) {
    // Subscribing in the same synchronous block as the initial add leaves no
    // window in which a change could be missed.
    listener.add(_value);
    final subscription = _changes.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  Future<void> close() => _changes.close();
}
