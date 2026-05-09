/// Reactive state management extensions for navhost.
///
/// Provides [Rx] reactive values with `.obs`, auto-tracking [Obs] widget,
/// scoped ViewModel management via [ViewModelScope] and
/// [ViewModelContextExtension.viewModel], and convenience builders
/// ([ViewModelBuilder], [Listen]).
///
/// ```dart
/// class CounterViewModel extends ChangeNotifier {
///   final count = 0.obs;
///   void increment() => count.value++;
/// }
///
/// // Wrap routes with rxRoutes for automatic scoping:
/// final nav = NavController(routes: rxRoutes([
///   NavRoute('/', (_, _) => CounterPage()),
/// ]));
///
/// // In a route widget:
/// final vm = context.viewModel(() => CounterViewModel());
/// return Obs(() => Text('${vm.count.value}'));
/// ```
library;

export 'src/rx.dart';
export 'src/view_model_builder.dart';
export 'src/view_model_store.dart'
    show ViewModelScope, ViewModelContextExtension, rxRoutes;
