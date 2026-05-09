# navhost_state

Reactive state management for [navhost](https://github.com/mathias8dev/navhost).

`navhost_state` brings GetX-style `.obs` reactive values and `Obs` auto-tracking widgets to Flutter, along with scoped ViewModel management tied to the widget lifecycle.

## Features

- **`.obs` reactive values** — wrap any value in `Rx<T>` with `0.obs`, `'hello'.obs`, `false.obs`
- **`Obs` auto-tracking widget** — rebuilds only when the `Rx` values read inside it change
- **Fine-grained rebuilds** — each `Obs` tracks its own dependencies independently
- **Scoped ViewModels** — `context.viewModel()` creates once, reuses across rebuilds, auto-cleans on unmount
- **`ViewModelScope`** — ties ViewModel lifecycle to the widget tree
- **`rxRoutes()`** — wraps all navhost routes with `ViewModelScope` automatically
- **`ViewModelBuilder`** — convenience widget that creates + subscribes in one step
- **`Listen`** — subscribes to an existing ViewModel without re-creating it

## Getting started

```yaml
dependencies:
  navhost: ^0.1.0
  navhost_state: ^0.1.0
```

```dart
import 'package:navhost/navhost.dart';
import 'package:navhost_state/navhost_state.dart';
```

## Usage

### Reactive values with `.obs` and `Obs`

```dart
final count = 0.obs;

// Obs rebuilds automatically when count.value changes
Obs(() => Text('${count.value}'))

// Only notifies when value actually changes
count.value = 5;  // triggers rebuild
count.value = 5;  // no-op — same value
```

### Multiple `Obs` watching the same value

```dart
final name = 'World'.obs;

Column(children: [
  Obs(() => Text('Hello, ${name.value}!')),   // rebuilds on change
  Obs(() => Text('Length: ${name.value.length}')), // also rebuilds
])
```

Each `Obs` tracks only the `Rx` values it actually reads — unrelated changes don't cause rebuilds.

### ViewModel with `.obs`

ViewModels don't need to extend `ChangeNotifier`. Plain classes work perfectly with `.obs` + `Obs`:

```dart
class CounterViewModel {
  final count = 0.obs;
  void increment() => count.value++;
}
```

`ViewModelBuilder` and `Listen` still require `ChangeNotifier` because they use `ListenableBuilder` internally. For plain class ViewModels, use `context.viewModel()` + `Obs` instead.

### Scoped ViewModel with `rxRoutes`

`rxRoutes()` wraps each route with a `ViewModelScope`, so `context.viewModel()` just works:

```dart
final nav = NavController(
  routes: rxRoutes([
    NavRoute('/', (_) => const CounterPage()),
    NavRoute('/detail/:id', (p) => DetailPage(id: p['id']!)),
  ]),
);
```

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.viewModel(() => CounterViewModel());

    return Obs(() => Column(
      children: [
        Text('Count: ${vm.count.value}'),
        FilledButton(
          onPressed: vm.increment,
          child: const Text('Increment'),
        ),
      ],
    ));
  }
}
```

The ViewModel is created once and reused across rebuilds. It is disposed when the route is removed from the navigation stack.

### Manual `ViewModelScope`

You can use `ViewModelScope` directly without `rxRoutes()`:

```dart
NavRoute(
  '/counter',
  (_) => ViewModelScope(
    child: CounterPage(),
  ),
)
```

### `ViewModelBuilder`

Creates a scoped ViewModel and subscribes to it in one widget:

```dart
ViewModelBuilder<CounterViewModel>(
  factory: () => CounterViewModel(),
  builder: (context, vm, child) => Obs(() =>
    Text('Count: ${vm.count.value}'),
  ),
)
```

### `Listen`

Subscribes to an existing ViewModel without re-creating it:

```dart
Listen<CounterViewModel>(
  builder: (context, vm) => Text('Count: ${vm.count}'),
)
```

### Without navhost — plain `StatefulWidget`

The reactive system works independently of navhost. You can use `.obs` and `Obs` anywhere:

```dart
class CounterPage extends StatefulWidget {
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final count = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Obs(() => Text('${count.value}'));
  }
}
```

## Example

See the [example app](example/) for demos of all features: reactive counter, ViewModelBuilder, multiple observers with a color picker, and a todo list.

## License

MIT
