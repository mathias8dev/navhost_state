part of 'rx.dart';

/// Runs [fn] immediately and re-runs it whenever any [Rx] value read
/// inside [fn] changes. Returns an [Effect] handle that can be disposed
/// to stop tracking.
///
/// ```dart
/// final name = 'Alice'.obs;
///
/// final e = effect(() => print('Hello, ${name.value}'));
/// // prints: Hello, Alice
///
/// name.value = 'Bob';
/// // prints: Hello, Bob
///
/// e.dispose(); // stops reacting
/// name.value = 'Carol'; // nothing printed
/// ```
Effect effect(void Function() fn) => Effect._(fn);

/// Handle returned by [effect]. Call [dispose] to stop the effect.
class Effect {
  final void Function() _fn;
  Set<Rx> _deps = {};
  bool _disposed = false;

  Effect._(this._fn) {
    _run();
  }

  void _run() {
    if (_disposed) return;

    for (final dep in _deps) {
      dep._removeListener(_run);
    }

    final tracker = _RxTracker();
    final prev = _RxTracker.current;
    _RxTracker.current = tracker;
    _fn();
    _RxTracker.current = prev;

    _deps = tracker._tracked;
    for (final dep in _deps) {
      dep._addListener(_run);
    }
  }

  /// Stops this effect from reacting to further [Rx] changes.
  void dispose() {
    _disposed = true;
    for (final dep in _deps) {
      dep._removeListener(_run);
    }
    _deps = {};
  }
}
