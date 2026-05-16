# navhost_state

Reactive state management for [navhost](https://github.com/mathias8dev/navhost).

`navhost_state` brings GetX-style `.obs` reactive values and `Obs` / `ObsBuilder` auto-tracking widgets to Flutter, along with optional scoped ViewModel management tied to the widget lifecycle.

## Table of contents

- [Getting started](#getting-started)
- [Core concepts](#core-concepts)
- [Usage](#usage)
  - [Reactive values with `.obs`](#reactive-values-with-obs)
  - [`Obs` and `ObsBuilder`](#obs-and-obsbuilder)
  - [`batch`](#batch)
  - [`computed`](#computed)
  - [`effect`](#effect)
  - [Reactive collections](#reactive-collections)
  - [`Rx.toStream` / `fromStream`](#rxtostream--fromstream)
  - [`ViewModel` lifecycle](#viewmodel-lifecycle)
  - [Collection extensions](#collection-extensions)
  - [ViewModel with private `Rx`](#viewmodel-with-private-rx)
  - [Complex state example](#complex-state-example)
  - [Without navhost](#without-navhost)
- [Recommended pattern: state hoisting](#recommended-pattern-state-hoisting)
- [Alternative: scoped ViewModels](#alternative-scoped-viewmodels)
  - [`rxRoutes` and `context.viewModel`](#rxroutes-and-contextviewmodel)
  - [Manual `ViewModelScope`](#manual-viewmodelscope)
  - [`ViewModelBuilder`](#viewmodelbuilder)
  - [`Listen`](#listen)
- [Integration with other libraries](#integration-with-other-libraries)
- [Migrating from other state management libraries](#migrating-from-other-state-management-libraries)
- [Example](#example)
- [License](#license)

## Getting started

```yaml
dependencies:
  navhost: ^latest
  navhost_state: ^latest
```

```dart
import 'package:navhost/navhost.dart';
import 'package:navhost_state/navhost_state.dart';
```

## Core concepts

| Concept | Description |
|---------|-------------|
| `Rx<T>` | Reactive wrapper around a value. Reading `.value` inside `Obs` registers a dependency. |
| `.obs` | Extension that wraps any value in `Rx<T>`: `0.obs`, `'hello'.obs`, `false.obs`. |
| `Rx.update(fn)` | Updates value by applying a function to the current value. |
| `computed(() => ...)` | Read-only `Rx` derived from other `Rx` values; updates automatically. |
| `effect(() { })` | Runs a callback immediately and re-runs it when tracked `Rx` values change. |
| `batch(() { })` | Defers all `Rx` notifications until the callback returns — one rebuild instead of many. |
| `RxList<E>` | Reactive `List` — notifies on in-place mutations (`add`, `remove`, etc.). |
| `RxMap<K,V>` | Reactive `Map` — notifies on in-place mutations (`[]=`, `remove`, etc.). |
| `RxSet<E>` | Reactive `Set` — notifies on in-place mutations (`add`, `remove`, etc.). |
| `Rx.toStream()` | Exposes an `Rx` as a `Stream` of future changes. |
| `fromStream(stream, initial:)` | Creates an `Rx` that syncs from a `Stream`. |
| `Obs` | Widget that rebuilds automatically when any `Rx` value read inside its builder changes. |
| `ObsBuilder` | Same as `Obs`, but the builder receives a `BuildContext`. |
| `ViewModel` | Base class with `onInit()` / `onDispose()` lifecycle hooks. |
| `ViewModelScope` | Ties a ViewModel's lifecycle to the widget tree (alternative pattern). |
| `rxRoutes()` | Wraps navhost routes with `ViewModelScope` automatically (alternative pattern). |

## Usage

### Reactive values with `.obs`

```dart
final count = 0.obs;

count.value = 5;  // triggers rebuild of any Obs reading it
count.value = 5;  // no-op — same value, no rebuild
```

Any Dart type can be made reactive:

```dart
final name    = 'World'.obs;
final visible = true.obs;
final items   = Rx<List<String>>([]);
final user    = Rx<User?>(null);
```

Use `update` to derive a new value from the current one:

```dart
count.update((prev) => prev + 1);
items.update((prev) => [...prev, 'new item']);
```

`update` reads the current value without registering a tracking dependency, then assigns the result through the normal setter (equality-checked, notifies subscribers only on change).

### `Obs` and `ObsBuilder`

`Obs` takes a positional builder with no context:

```dart
Obs(() => Text('${count.value}'))
```

`ObsBuilder` takes a named builder with `BuildContext` — use it when you need the theme, a navigator, or a dialog:

```dart
ObsBuilder(
  builder: (context) => Text(
    '${count.value}',
    style: Theme.of(context).textTheme.headlineMedium,
  ),
)
```

Both track only the `Rx` values actually read during the build — unrelated changes don't cause a rebuild.

### `batch`

Defer all notifications from multiple `Rx` changes and flush them together, causing a single rebuild instead of one per change:

```dart
batch(() {
  _firstName.value = 'Jane';
  _lastName.value  = 'Doe';
  _age.value       = 30;
}); // one rebuild
```

Nested `batch` calls are safe — the flush happens only when the outermost batch returns.

### `computed`

A read-only `Rx` whose value is derived from other `Rx` values and updates automatically when any dependency changes:

```dart
final firstName = 'Jane'.obs;
final lastName  = 'Doe'.obs;
final fullName  = computed(() => '${firstName.value} ${lastName.value}');

print(fullName.value); // Jane Doe
firstName.value = 'John';
print(fullName.value); // John Doe — updated automatically
```

Assigning to a `computed` throws `UnsupportedError`. Update its dependencies instead.

### `effect`

Runs a callback immediately and re-runs it whenever any `Rx` value read inside it changes. Returns an `Effect` handle — call `dispose()` to stop:

```dart
final name = 'Alice'.obs;

final e = effect(() => print('Hello, ${name.value}'));
// prints: Hello, Alice

name.value = 'Bob';
// prints: Hello, Bob

e.dispose(); // stops reacting
```

### Reactive collections

`RxList`, `RxMap`, and `RxSet` notify `Obs` on in-place mutations without requiring a full value reassignment:

```dart
final items  = RxList<String>();
final scores = RxMap<String, int>();
final tags   = RxSet<String>();

items.add('hello');     // triggers rebuild
scores['Alice'] = 10;   // triggers rebuild
tags.add('flutter');    // triggers rebuild
```

Read via `.value` (returns an unmodifiable view) or the built-in query methods — all tracked:

```dart
Obs(() => Column(children: [
  Text('${items.length} items'),
  Text(items.sortedBy((e) => e).joinToString()),
  Text(scores.filterValues((v) => v > 5).keys.join(', ')),
]))
```

See [collection extensions](#collection-extensions) for the full query API.

### `Rx.toStream` / `fromStream`

Interop with stream-based APIs:

```dart
// Stream of future changes (does not emit current value on listen)
final sub = count.toStream().listen(print);
count.value = 1; // prints 1 synchronously

// Rx backed by a Stream
final rx = fromStream(priceStream, initial: 0.0);
Obs(() => Text('${rx.value}'))
```

### `ViewModel` lifecycle

Extend `ViewModel` to get `onInit` and `onDispose` hooks that fire automatically inside `ViewModelScope`:

```dart
class PostListViewModel extends ViewModel {
  final _posts = RxList<Post>();
  List<Post> get posts => _posts.value;

  @override
  void onInit() => loadPosts();

  @override
  void onDispose() => _subscription?.cancel();
}
```

With `rxRoutes()` / `ViewModelScope`, `onInit` and `onDispose` are called automatically. With state hoisting, call them yourself:

```dart
class _PostListPageState extends State<PostListPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.onInit();
  }

  @override
  void dispose() {
    widget.viewModel.onDispose();
    super.dispose();
  }
  // ...
}
```

### Collection extensions

`navhost_state` exports Kotlin-inspired collection extensions on plain Dart collections, built on top of `package:collection`. They work on any `Iterable`, `List`, or `Map` — not just `Rx` types:

```dart
final numbers = [3, 1, 4, 1, 5, 9, 2, 6];

// Filtering
numbers.filterNot((n) => n > 5);                   // [3, 1, 4, 1, 2]
numbers.singleOrNull((n) => n == 9);               // 9
numbers.count((n) => n.isOdd);                     // 5
numbers.distinctBy((n) => n);                      // [3, 1, 4, 5, 9, 2, 6]

// Grouping and slicing
numbers.groupBy((n) => n.isOdd ? 'odd' : 'even'); // {odd: [3,1,1,5,9], even: [4,2,6]}
numbers.chunked(3);                                // [[3,1,4], [1,5,9], [2,6]]
numbers.partition((n) => n > 4);                   // ([5, 9, 6], [3, 1, 4, 1, 2])

// Aggregation
numbers.sumOf((n) => n);                           // 31
numbers.minByOrNull((n) => n);                     // 1
numbers.maxByOrNull((n) => n);                     // 9

// Transformation
numbers.flatMap((n) => [n, n * 2]);               // [3, 6, 1, 2, 4, 8, ...]
numbers.joinToString(separator: ', ');             // '3, 1, 4, 1, 5, 9, 2, 6'
numbers.drop(3);                                   // [1, 5, 9, 2, 6]

// Association
numbers.associateBy((n) => 'key_$n');             // {'key_3': 3, 'key_1': 1, ...}
```

**`Iterable<E>`** — `singleOrNull`, `filterNot`, `groupBy`, `chunked`, `count`, `sumOf`, `minByOrNull`, `maxByOrNull`, `associateBy`, `associate`, `partition`, `distinctBy`, `flatMap`, `zip`, `joinToString`, `onEach`, `drop`, `dropWhile`

**`List<E>`** — `sortedByDescending`, `indices` (plus `sortedBy`, `forEachIndexed`, `mapIndexed`, `whereNot`, `slices` from `package:collection`)

**`Map<K,V>`** — `mapValues`, `mapKeys`, `filterKeys`, `filterValues`, `filter`, `getOrDefault`, `getOrElse`, `none`, `all`, `count`, `minByOrNull`, `maxByOrNull`, `toList`

All query methods on `RxList`, `RxMap`, and `RxSet` are tracked — reading them inside `Obs` registers a dependency.

### ViewModel with private `Rx`

Keep `Rx` fields private and expose plain values through getters. Callers get a clean API with no `.value` noise, while `Obs` still tracks changes because the getter reads `.value` internally:

```dart
class CounterViewModel {
  final _count = 0.obs;
  int get count => _count.value;  // public value, private Rx

  void increment() => _count.value++;
  void reset()     => _count.value = 0;
}
```

```dart
class CounterPage extends StatelessWidget {
  final CounterViewModel viewModel;
  const CounterPage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Obs(() => Column(
      children: [
        Text('${viewModel.count}'),  // no .value at the call site
        FilledButton(onPressed: viewModel.increment, child: const Text('+')),
      ],
    ));
  }
}
```

Mutation is only possible through the ViewModel's own methods — the `Rx` cannot be replaced or observed directly from outside.

### Complex state example

A realistic ViewModel with multiple reactive fields, async loading, error handling, and derived state:

```dart
class PostListViewModel {
  final PostRepository _repo;
  PostListViewModel(this._repo);

  final _posts          = Rx<List<Post>>([]);
  final _isLoadingPosts = false.obs;
  final _postsError     = Rx<String?>(null);
  final _searchQuery    = ''.obs;

  List<Post>  get posts          => _posts.value;
  bool        get isLoadingPosts => _isLoadingPosts.value;
  String?     get postsError     => _postsError.value;
  String      get searchQuery    => _searchQuery.value;

  // Derived state — tracked by Obs because it reads reactive getters
  List<Post> get filteredPosts => searchQuery.isEmpty
      ? posts
      : posts.where((p) => p.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  bool get isPostsEmpty => !isLoadingPosts && postsError == null && filteredPosts.isEmpty;

  Future<void> loadPosts() async {
    _isLoadingPosts.value = true;
    _postsError.value = null;
    try {
      _posts.value = await _repo.fetchPosts();
    } catch (e) {
      _postsError.value = e.toString();
    } finally {
      _isLoadingPosts.value = false;
    }
  }

  void searchPosts(String q) => _searchQuery.value = q;
}
```

The page wraps its body in a single `Obs` — the standard approach when a ViewModel owns a whole page:

```dart
class PostListPage extends StatefulWidget {
  final PostListViewModel viewModel;
  const PostListPage({super.key, required this.viewModel});

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: Obs(() => Column(
        children: [
          TextField(
            onChanged: vm.searchPosts,
            decoration: InputDecoration(
              hintText: 'Search...',
              suffixIcon: vm.searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => vm.searchPosts(''))
                  : null,
            ),
          ),
          Expanded(child: switch (true) {
            _ when vm.isLoadingPosts  => const Center(child: CircularProgressIndicator()),
            _ when vm.postsError != null => Center(child: Text(vm.postsError!)),
            _ when vm.isPostsEmpty    => const Center(child: Text('No posts found.')),
            _ => ListView.builder(
                itemCount: vm.filteredPosts.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(vm.filteredPosts[i].title),
                  subtitle: Text(vm.filteredPosts[i].body, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
          }),
        ],
      )),
    );
  }
}
```

Wired up via state hoisting:

```dart
NavRoute('/posts', (_, _) => PostListPage(
  viewModel: PostListViewModel(getIt<PostRepository>()),
)),
```

### Without navhost

The reactive system works independently of navhost — use `.obs` and `Obs` in any widget:

```dart
class CounterPage extends StatefulWidget {
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final _count = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Obs(() => Text('${_count.value}'));
  }
}
```

## Recommended pattern: state hoisting

**State hoisting** is the idea that a widget should not own its own state — it should receive state from above and report events back up. The widget becomes a pure function of its inputs: given the same ViewModel, it always produces the same UI. State lives at the route boundary, not inside the widget tree.

In practice: create the ViewModel in the route builder, pass it as a constructor parameter, and let the page read from it and call its methods. Nothing is looked up implicitly.

```dart
// State lives here — at the route boundary
NavController(
  routes: [
    NavRoute('/counter', (_, _) => CounterPage(
      viewModel: CounterViewModel(),
    )),
  ],
)

// Page receives state — it owns nothing
class CounterPage extends StatelessWidget {
  final CounterViewModel viewModel;
  const CounterPage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Obs(() => Column(
      children: [
        Text('${viewModel.count}'),                           // reads state
        FilledButton(
          onPressed: viewModel.increment,                    // reports event up
          child: const Text('+'),
        ),
      ],
    ));
  }
}
```

Data flows in one direction: **state down, events up**. The ViewModel holds state and exposes it through getters. The page reads those getters and calls methods in response to user actions. Neither side knows how the other works internally.

```
Route builder
  └── creates CounterViewModel          ← state lives here
        └── passes to CounterPage
              ├── reads viewModel.count  ← state flows down
              └── calls viewModel.increment  ← events flow up
```

The ViewModel is created once when the route is built and garbage-collected when the route is popped — no explicit lifecycle management needed.

**Why this approach?**

- **Testable by construction.** To test a page, instantiate it with a mock or stub ViewModel — no widget tree setup, no `InheritedWidget` wiring, no `ProviderScope`. The page is just a function of its input.
- **Explicit dependencies.** Everything the page needs is visible at the call site. There are no implicit lookups (`context.read`, `Get.find`, `context.viewModel`) that require the caller to know what the widget will search for at runtime.
- **Framework-agnostic state.** The ViewModel is a plain Dart class — no `BuildContext`, no `Widget`. Business logic stays pure and can be tested without Flutter.
- **Predictable lifetime.** The ViewModel's lifetime mirrors the route's lifetime exactly. No stale state across navigation, no manual disposal.
- **DI-friendly.** Resolve dependencies from `get_it` (or any container) in the route builder, pass them in, done. The page never touches the DI layer.

`ViewModelScope`, `rxRoutes()`, and `context.viewModel()` remain available for cases where hoisting isn't practical (deeply nested widgets, shared ViewModels across sibling routes). See [Alternative: scoped ViewModels](#alternative-scoped-viewmodels).

## Alternative: scoped ViewModels

When state hoisting isn't practical — deeply nested widgets, shared state across sibling routes — use the scoped ViewModel system instead.

### `rxRoutes` and `context.viewModel`

`rxRoutes()` wraps each route with a `ViewModelScope`, enabling `context.viewModel()`:

```dart
final nav = NavController(
  routes: rxRoutes([
    NavRoute('/', (_, _) => const CounterPage()),
    NavRoute('/detail/:id', (p, _) => DetailPage(id: p['id']!)),
  ]),
);
```

```dart
class CounterViewModel {
  final _count = 0.obs;
  int get count => _count.value;
  void increment() => _count.value++;
}

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.viewModel(() => CounterViewModel());
    return Obs(() => Column(
      children: [
        Text('Count: ${vm.count}'),
        FilledButton(onPressed: vm.increment, child: const Text('Increment')),
      ],
    ));
  }
}
```

The ViewModel is created once and reused across rebuilds. It is disposed when the route is removed from the stack.

### Manual `ViewModelScope`

Use `ViewModelScope` directly without `rxRoutes()`:

```dart
NavRoute('/counter', (_, _) => ViewModelScope(child: CounterPage()))
```

### `ViewModelBuilder`

Creates a scoped ViewModel and subscribes to it in one widget. Requires `ChangeNotifier`:

```dart
ViewModelBuilder<CounterViewModel>(
  factory: () => CounterViewModel(),
  builder: (context, vm, child) => Text('Count: ${vm.count}'),
)
```

### `Listen`

Subscribes to an existing scoped ViewModel without re-creating it. Requires `ChangeNotifier`:

```dart
Listen<CounterViewModel>(
  builder: (context, vm) => Text('Count: ${vm.count}'),
)
```

## Integration with other libraries

`navhost_state` is unopinionated about dependency injection. The examples below follow the recommended pattern of private `Rx` fields with public getters.

### get_it

```dart
class UserViewModel {
  final _api  = GetIt.I<ApiService>();
  final _auth = GetIt.I<AuthRepository>();

  final _user    = Rx<User?>(null);
  final _loading = false.obs;

  User?  get user    => _user.value;
  bool   get loading => _loading.value;

  Future<void> loadUser(String id) async {
    _loading.value = true;
    _user.value = await _api.fetchUser(id, token: _auth.token);
    _loading.value = false;
  }
}

// Hoisted into the route
NavRoute('/user/:id', (p, _) => UserPage(
  viewModel: UserViewModel(),
))
```

### dio

```dart
class PostsViewModel {
  final _dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

  final _posts = Rx<List<Post>>([]);
  final _error = Rx<String?>(null);

  List<Post> get posts => _posts.value;
  String?    get error => _error.value;

  Future<void> fetch() async {
    try {
      final response = await _dio.get('/posts');
      _posts.value = (response.data as List).map(Post.fromJson).toList();
    } on DioException catch (e) {
      _error.value = e.message;
    }
  }
}
```

### shared_preferences

```dart
class SettingsViewModel {
  final _darkMode = false.obs;
  final _locale   = 'en'.obs;

  bool   get darkMode => _darkMode.value;
  String get locale   => _locale.value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode.value = prefs.getBool('darkMode') ?? false;
    _locale.value   = prefs.getString('locale')  ?? 'en';
  }

  Future<void> toggleDarkMode() async {
    _darkMode.value = !_darkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode.value);
  }
}
```

### flutter_secure_storage

```dart
class SessionViewModel {
  final _storage = const FlutterSecureStorage();

  final _isLoggedIn = false.obs;
  final _token      = Rx<String?>(null);

  bool    get isLoggedIn => _isLoggedIn.value;
  String? get token      => _token.value;

  Future<void> restore() async {
    _token.value      = await _storage.read(key: 'auth_token');
    _isLoggedIn.value = _token.value != null;
  }

  Future<void> login(String newToken) async {
    await _storage.write(key: 'auth_token', value: newToken);
    _token.value      = newToken;
    _isLoggedIn.value = true;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _token.value      = null;
    _isLoggedIn.value = false;
  }
}
```

### firebase

```dart
class AuthViewModel {
  final _user = Rx<User?>(FirebaseAuth.instance.currentUser);
  User? get user => _user.value;

  AuthViewModel() {
    FirebaseAuth.instance.authStateChanges().listen((u) => _user.value = u);
  }

  Future<void> signIn(String email, String password) =>
      FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
```

### freezed

```dart
class ProfileViewModel {
  final _profile = Rx<UserProfile?>(null);
  final _saving  = false.obs;

  UserProfile? get profile => _profile.value;
  bool         get saving  => _saving.value;

  void updateName(String name) =>
      _profile.value = _profile.value?.copyWith(name: name);

  Future<void> save() async {
    _saving.value = true;
    await api.updateProfile(_profile.value!);
    _saving.value = false;
  }
}
```

## Migrating from other state management libraries

All approaches coexist in the same widget tree — migrate one screen at a time.

### From Provider / ChangeNotifierProvider

```dart
// Before
class CounterModel extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  void increment() { _count++; notifyListeners(); }
}
ChangeNotifierProvider(
  create: (_) => CounterModel(),
  child: Consumer<CounterModel>(
    builder: (context, model, _) => Text('${model.count}'),
  ),
)

// After
class CounterViewModel {
  final _count = 0.obs;
  int get count => _count.value;
  void increment() => _count.value++;
}
// Hoisted into the route — no Provider needed
NavRoute('/', (_, _) => CounterPage(viewModel: CounterViewModel()))
```

### From Riverpod

```dart
// Before
final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);
// In a ConsumerWidget
final count = ref.watch(counterProvider);
return Text('$count');

// After
class CounterViewModel {
  final _count = 0.obs;
  int get count => _count.value;
  void increment() => _count.value++;
}
NavRoute('/', (_, _) => CounterPage(viewModel: CounterViewModel()))
```

`ProviderScope` and navhost_state coexist — screens using `ref.watch` and screens using `Obs` can live in the same app.

### From GetX

```dart
// Before
class CounterController extends GetxController {
  final count = 0.obs;
  void increment() => count++;
}
Get.put(CounterController());
return Obx(() => Text('${Get.find<CounterController>().count}'));

// After
class CounterViewModel {
  final _count = 0.obs;
  int get count => _count.value;
  void increment() => _count.value++;
}
NavRoute('/', (_, _) => CounterPage(viewModel: CounterViewModel()))
```

Key differences from GetX: ViewModels are scoped to the route (not global), `.value` is explicit, and there is no `Get.put` / `Get.find`.

### From Bloc / Cubit

```dart
// Before
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}
BlocProvider(
  create: (_) => CounterCubit(),
  child: BlocBuilder<CounterCubit, int>(
    builder: (context, count) => Text('$count'),
  ),
)

// After
class CounterViewModel {
  final _count = 0.obs;
  int get count => _count.value;
  void increment() => _count.value++;
}
NavRoute('/', (_, _) => CounterPage(viewModel: CounterViewModel()))
```

`BlocProvider` and navhost_state don't interfere — existing routes keep their `BlocProvider` wrappers while new routes use hoisting.

## Example

See the [example app](example/) for demos of all features: reactive counter, ViewModelBuilder, multiple observers with a color picker, and a todo list.

## License

MIT
