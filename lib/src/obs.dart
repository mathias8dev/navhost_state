part of 'rx.dart';

/// A widget that automatically rebuilds when any [Rx] value read inside
/// its [builder] changes.
///
/// ```dart
/// final count = 0.obs;
///
/// Obs(() => Text('${count.value}'))
/// ```
///
/// Only the [Rx] values accessed during [builder] are tracked — if a value
/// is conditionally read, the subscription updates on each rebuild.
class Obs extends StatefulWidget {
  /// Builder that returns the widget tree. Any [Rx.value] read inside
  /// is automatically tracked.
  final Widget Function() builder;

  /// Creates an [Obs] widget that rebuilds when tracked [Rx] values change.
  const Obs(this.builder, {super.key});

  @override
  State<Obs> createState() => _ObsState();
}

class _ObsState extends State<Obs> {
  Set<Rx> _subscriptions = {};

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    for (final rx in _subscriptions) {
      rx._removeListener(_rebuild);
    }

    final tracker = _RxTracker();
    _RxTracker.current = tracker;
    final result = widget.builder();
    _RxTracker.current = null;

    _subscriptions = tracker._tracked;
    for (final rx in _subscriptions) {
      rx._addListener(_rebuild);
    }

    return result;
  }

  @override
  void dispose() {
    for (final rx in _subscriptions) {
      rx._removeListener(_rebuild);
    }
    super.dispose();
  }
}
