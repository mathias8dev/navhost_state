part of 'rx.dart';

/// Returns a read-only [Rx] whose value is derived from other [Rx] values.
/// The computed value updates automatically whenever its dependencies change.
///
/// ```dart
/// final first = 'Jane'.obs;
/// final last  = 'Doe'.obs;
/// final full  = computed(() => '${first.value} ${last.value}');
///
/// print(full.value); // Jane Doe
/// first.value = 'John';
/// print(full.value); // John Doe
/// ```
Rx<T> computed<T>(T Function() compute) => _ComputedRx<T>(compute);

class _ComputedRx<T> extends Rx<T> {
  final T Function() _compute;
  Set<Rx> _deps = {};

  _ComputedRx._(T Function() compute, super.initialValue)
      : _compute = compute;

  factory _ComputedRx(T Function() compute) {
    final tracker = _RxTracker();
    final prev = _RxTracker.current;
    _RxTracker.current = tracker;
    final value = compute();
    _RxTracker.current = prev;

    final rx = _ComputedRx._(compute, value);
    rx._deps = tracker._tracked;
    for (final dep in rx._deps) {
      dep._addListener(rx._recompute);
    }
    return rx;
  }

  void _recompute() {
    for (final dep in _deps) {
      dep._removeListener(_recompute);
    }

    final tracker = _RxTracker();
    final prev = _RxTracker.current;
    _RxTracker.current = tracker;
    final result = _compute();
    _RxTracker.current = prev;

    _deps = tracker._tracked;
    for (final dep in _deps) {
      dep._addListener(_recompute);
    }

    if (_value != result) {
      _value = result;
      _notify();
    }
  }

  @override
  set value(T _) => throw UnsupportedError(
      'computed Rx is read-only — update its dependencies instead.');
}
