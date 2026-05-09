import 'package:flutter/widgets.dart';

import 'view_model_store.dart';

/// A convenience widget that creates a scoped [ChangeNotifier] and rebuilds
/// when it notifies. For plain (non-[ChangeNotifier]) ViewModels, use
/// [ViewModelContextExtension.viewModel] with [Obs] instead.
///
/// Combines [ViewModelContextExtension.viewModel] with [ListenableBuilder]
/// so you don't need to wire them up manually.
///
/// ```dart
/// ViewModelBuilder<CounterViewModel>(
///   factory: () => CounterViewModel(),
///   builder: (context, vm, child) => Text('${vm.count}'),
/// )
/// ```
class ViewModelBuilder<T extends ChangeNotifier> extends StatelessWidget {
  /// Factory called once to create the [ChangeNotifier] for this scope.
  final T Function() factory;

  /// Builder called whenever the [ChangeNotifier] notifies listeners.
  final Widget Function(BuildContext context, T viewModel, Widget? child)
      builder;

  /// Optional child widget that does not depend on the view model.
  final Widget? child;

  /// Creates a [ViewModelBuilder] that scopes [T] to the nearest [ViewModelScope].
  const ViewModelBuilder({
    super.key,
    required this.factory,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.viewModel<T>(factory);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, child) => builder(context, vm, child),
      child: child,
    );
  }
}

/// A widget that listens to an existing scoped [ChangeNotifier] and rebuilds
/// when it notifies.
///
/// Use this when the ViewModel was already created via [context.viewModel]
/// higher in the tree.
///
/// ```dart
/// Listen<CounterViewModel>(
///   builder: (context, vm) => Text('${vm.count}'),
/// )
/// ```
class Listen<T extends ChangeNotifier> extends StatelessWidget {
  /// Builder called whenever the [ChangeNotifier] notifies listeners.
  final Widget Function(BuildContext context, T viewModel) builder;

  /// Creates a [Listen] widget that looks up [T] from the nearest
  /// [ViewModelScope] and rebuilds on changes.
  const Listen({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.viewModel<T>(_throw);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => builder(context, vm),
    );
  }

  static Never _throw() {
    throw StateError(
      'Listen<T> requires the ViewModel to be created first via '
      'context.viewModel() or ViewModelBuilder.',
    );
  }
}
