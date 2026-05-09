import 'package:flutter/widgets.dart';
import 'package:navhost/navhost.dart';

/// A scope that retains ViewModels across rebuilds and cleans them up when
/// this widget is removed from the tree.
///
/// ViewModels can be any object. If a stored object is a [ChangeNotifier],
/// its [ChangeNotifier.dispose] method is called automatically on cleanup.
///
/// Use [rxRoutes] to automatically wrap every [NavRoute] with a
/// [ViewModelScope], or add one manually:
///
/// ```dart
/// NavRoute('/counter', (_, _) => ViewModelScope(child: CounterPage()))
/// ```
class ViewModelScope extends StatefulWidget {
  /// The child widget that can access scoped ViewModels via
  /// [ViewModelContextExtension.viewModel].
  final Widget child;

  /// Creates a ViewModel scope around [child].
  const ViewModelScope({super.key, required this.child});

  @override
  State<ViewModelScope> createState() => _ViewModelScopeState();
}

class _ViewModelScopeState extends State<ViewModelScope> {
  final _models = <Type, Object>{};

  T getOrCreate<T extends Object>(T Function() factory) {
    return _models.putIfAbsent(T, factory) as T;
  }

  @override
  void dispose() {
    for (final vm in _models.values) {
      if (vm is ChangeNotifier) vm.dispose();
    }
    _models.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ViewModelScopeInherited(state: this, child: widget.child);
  }
}

class _ViewModelScopeInherited extends InheritedWidget {
  final _ViewModelScopeState state;

  const _ViewModelScopeInherited({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ViewModelScopeInherited oldWidget) =>
      state != oldWidget.state;
}

/// Convenience extensions on [BuildContext] for scoped ViewModel access.
extension ViewModelContextExtension on BuildContext {
  /// Returns a scoped object tied to the nearest [ViewModelScope].
  ///
  /// The ViewModel can be any object — it does not need to extend
  /// [ChangeNotifier]. Use `.obs` fields and [Obs] for reactivity instead.
  ///
  /// The object is created once via [factory] and reused on subsequent
  /// calls. If it is a [ChangeNotifier], it is automatically disposed when
  /// the enclosing [ViewModelScope] is removed from the widget tree.
  ///
  /// ```dart
  /// final vm = context.viewModel(() => CounterViewModel());
  /// ```
  T viewModel<T extends Object>(T Function() factory) {
    final inherited =
        dependOnInheritedWidgetOfExactType<_ViewModelScopeInherited>();
    assert(
      inherited != null,
      'No ViewModelScope found. Wrap your route with ViewModelScope '
      'or use rxRoutes() to wrap all routes automatically.',
    );
    return inherited!.state.getOrCreate<T>(factory);
  }
}

/// Wraps each route's builder with a [ViewModelScope] so that
/// [ViewModelContextExtension.viewModel] works automatically.
///
/// ```dart
/// final nav = NavController(
///   routes: rxRoutes([
///     NavRoute('/', (_, _) => HomePage()),
///     NavRoute('/detail/:id', (p, _) => DetailPage(id: p['id']!)),
///   ]),
/// );
/// ```
List<NavRoute> rxRoutes(List<NavRoute> routes) {
  return routes
      .map((route) => NavRoute(
            route.path,
            (params, queryParams) =>
                ViewModelScope(child: route.builder(params, queryParams)),
            enterTransition: route.enterTransition,
            exitTransition: route.exitTransition,
            popEnterTransition: route.popEnterTransition,
            popExitTransition: route.popExitTransition,
            transitionDuration: route.transitionDuration,
            reverseTransitionDuration: route.reverseTransitionDuration,
          ))
      .toList();
}
