part of 'rx.dart';

/// A widget that automatically rebuilds when any [Rx] value read inside
/// its [builder] changes. Unlike [Obs], the builder receives a [BuildContext].
///
/// ```dart
/// ObsBuilder(
///   builder: (context) => Text('${vm.count}'),
/// )
/// ```
///
/// Only the [Rx] values accessed during [builder] are tracked — if a value
/// is conditionally read, the subscription updates on each rebuild.
class ObsBuilder extends StatefulWidget {
  /// Builder that returns the widget tree. Any [Rx.value] read inside
  /// is automatically tracked.
  final Widget Function(BuildContext context) builder;

  const ObsBuilder({super.key, required this.builder});

  @override
  State<ObsBuilder> createState() => _ObsBuilderState();
}

class _ObsBuilderState extends State<ObsBuilder> {
  Set<Rx> _subscriptions = {};

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    for (final rx in _subscriptions) {
      rx._removeListener(_rebuild);
    }

    final tracker = _RxTracker();
    _RxTracker.current = tracker;
    final result = widget.builder(context);
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
