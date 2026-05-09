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
    NavRoute('/', (_, _) => const CounterPage()),
    NavRoute('/detail/:id', (p, _) => DetailPage(id: p['id']!)),
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
  (_, _) => ViewModelScope(
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

## Integration with other libraries

`navhost_state` is unopinionated about dependency injection — the `context.viewModel()` factory is just a function, so it works naturally with any DI solution.

### get_it

Use [get_it](https://pub.dev/packages/get_it) to inject services into your ViewModels:

```dart
// Register services
final getIt = GetIt.instance;
getIt.registerSingleton<ApiService>(ApiService());
getIt.registerSingleton<AuthRepository>(AuthRepository());

// ViewModel receives dependencies via get_it
class UserViewModel {
  final _api = GetIt.I<ApiService>();
  final _auth = GetIt.I<AuthRepository>();

  final user = Rx<User?>(null);
  final loading = false.obs;

  Future<void> loadUser(String id) async {
    loading.value = true;
    user.value = await _api.fetchUser(id, token: _auth.token);
    loading.value = false;
  }
}

// In your route
final vm = context.viewModel(() => UserViewModel());
return Obs(() => vm.loading.value
    ? const CircularProgressIndicator()
    : Text(vm.user.value?.name ?? 'No user'));
```

### injectable + get_it

With [injectable](https://pub.dev/packages/injectable), use constructor injection for cleaner setup:

```dart
@injectable
class OrderViewModel {
  final OrderRepository _repo;
  final orders = Rx<List<Order>>([]);

  OrderViewModel(this._repo);

  Future<void> load() async {
    orders.value = await _repo.getAll();
  }
}

// In your route — get_it resolves the constructor dependencies
final vm = context.viewModel(() => getIt<OrderViewModel>());
return Obs(() => ListView(
  children: vm.orders.value.map((o) => Text(o.title)).toList(),
));
```

### dio

Pair with [dio](https://pub.dev/packages/dio) for HTTP-driven state:

```dart
class PostsViewModel {
  final _dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

  final posts = Rx<List<Post>>([]);
  final error = Rx<String?>(null);

  Future<void> fetch() async {
    try {
      final response = await _dio.get('/posts');
      posts.value = (response.data as List).map(Post.fromJson).toList();
    } on DioException catch (e) {
      error.value = e.message;
    }
  }
}
```

### shared_preferences

Persist and restore reactive state with [shared_preferences](https://pub.dev/packages/shared_preferences):

```dart
class SettingsViewModel {
  final darkMode = false.obs;
  final locale = 'en'.obs;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    darkMode.value = prefs.getBool('darkMode') ?? false;
    locale.value = prefs.getString('locale') ?? 'en';
  }

  Future<void> toggleDarkMode() async {
    darkMode.value = !darkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode.value);
  }
}
```

### freezed

Use [freezed](https://pub.dev/packages/freezed) for immutable models with `copyWith` — a natural fit with `Rx`:

```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String name,
    required String email,
    @Default(false) bool verified,
  }) = _UserProfile;
}

class ProfileViewModel {
  final profile = Rx<UserProfile?>(null);
  final saving = false.obs;

  void updateName(String name) {
    profile.value = profile.value?.copyWith(name: name);
  }

  Future<void> save() async {
    saving.value = true;
    await api.updateProfile(profile.value!);
    saving.value = false;
  }
}
```

### hive

Local persistence with [hive](https://pub.dev/packages/hive):

```dart
class NotesViewModel {
  final notes = Rx<List<Note>>([]);
  late final Box<Note> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Note>('notes');
    notes.value = _box.values.toList();
  }

  Future<void> add(String text) async {
    final note = Note(text: text, createdAt: DateTime.now());
    await _box.add(note);
    notes.value = _box.values.toList();
  }

  Future<void> delete(int index) async {
    await _box.deleteAt(index);
    notes.value = _box.values.toList();
  }
}
```

### firebase

Firestore and Auth with [cloud_firestore](https://pub.dev/packages/cloud_firestore) and [firebase_auth](https://pub.dev/packages/firebase_auth):

```dart
class AuthViewModel {
  final user = Rx<User?>(FirebaseAuth.instance.currentUser);

  AuthViewModel() {
    FirebaseAuth.instance.authStateChanges().listen((u) {
      user.value = u;
    });
  }

  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}

class ChatViewModel {
  final messages = Rx<List<Message>>([]);

  ChatViewModel(String chatId) {
    FirebaseFirestore.instance
        .collection('chats/$chatId/messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      messages.value = snapshot.docs.map(Message.fromDoc).toList();
    });
  }
}
```

### web_socket_channel

Real-time data with [web_socket_channel](https://pub.dev/packages/web_socket_channel):

```dart
class LivePriceViewModel {
  final price = 0.0.obs;
  final connected = false.obs;
  late final WebSocketChannel _channel;

  void connect(String symbol) {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.example.com/prices/$symbol'),
    );
    connected.value = true;

    _channel.stream.listen(
      (data) => price.value = double.parse(data),
      onDone: () => connected.value = false,
    );
  }

  void disconnect() {
    _channel.sink.close();
    connected.value = false;
  }
}
```

### flutter_secure_storage

Secure token storage with [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage):

```dart
class SessionViewModel {
  final _storage = const FlutterSecureStorage();
  final isLoggedIn = false.obs;
  final token = Rx<String?>(null);

  Future<void> restore() async {
    token.value = await _storage.read(key: 'auth_token');
    isLoggedIn.value = token.value != null;
  }

  Future<void> login(String newToken) async {
    await _storage.write(key: 'auth_token', value: newToken);
    token.value = newToken;
    isLoggedIn.value = true;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    token.value = null;
    isLoggedIn.value = false;
  }
}
```

## Migrating from other state management libraries

If you're adopting navhost for navigation, you can migrate your state management incrementally — old and new screens coexist without conflict.

### From Provider / ChangeNotifierProvider

**Before:**
```dart
class CounterModel extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  void increment() {
    _count++;
    notifyListeners();
  }
}

// Provided at the top of the tree
ChangeNotifierProvider(
  create: (_) => CounterModel(),
  child: Consumer<CounterModel>(
    builder: (context, model, _) => Text('${model.count}'),
  ),
)
```

**After:**
```dart
class CounterViewModel {
  final count = 0.obs;
  void increment() => count.value++;
}

// Scoped to the route automatically via rxRoutes
final vm = context.viewModel(() => CounterViewModel());
return Obs(() => Text('${vm.count.value}'));
```

**During migration** — existing Provider screens keep working. New screens use `context.viewModel()` + `Obs`. No need to touch the `MultiProvider` setup until you're ready.

### From Riverpod

**Before:**
```dart
final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
}

// In a ConsumerWidget
final count = ref.watch(counterProvider);
return Text('$count');
```

**After:**
```dart
class CounterViewModel {
  final count = 0.obs;
  void increment() => count.value++;
}

final vm = context.viewModel(() => CounterViewModel());
return Obs(() => Text('${vm.count.value}'));
```

**During migration** — `ProviderScope` and `ViewModelScope` are independent. Screens using `ref.watch` and screens using `Obs` can coexist in the same app. Migrate one screen at a time.

### From GetX

**Before:**
```dart
class CounterController extends GetxController {
  final count = 0.obs;
  void increment() => count++;
}

// Global binding
Get.put(CounterController());
final ctrl = Get.find<CounterController>();
return Obx(() => Text('${ctrl.count}'));
```

**After:**
```dart
class CounterViewModel {
  final count = 0.obs;
  void increment() => count.value++;
}

final vm = context.viewModel(() => CounterViewModel());
return Obs(() => Text('${vm.count.value}'));
```

The API is intentionally similar. Key differences: ViewModels are **scoped to the route** (not global), and you use `.value` explicitly instead of operator overloading. No `Get.put` / `Get.find` — the widget tree owns the lifecycle.

### From Bloc / Cubit

**Before:**
```dart
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
```

**After:**
```dart
class CounterViewModel {
  final count = 0.obs;
  void increment() => count.value++;
}

final vm = context.viewModel(() => CounterViewModel());
return Obs(() => Text('${vm.count.value}'));
```

**During migration** — `BlocProvider` and `ViewModelScope` don't interfere. You can wrap new navhost routes with `rxRoutes()` while existing routes keep their `BlocProvider` wrappers.

### Migration tips

- **Migrate one screen at a time** — all approaches coexist in the same widget tree
- **Start with new screens** — use `context.viewModel()` + `Obs` for new routes, leave existing ones untouched
- **Move shared services last** — keep your repositories and API clients in get_it or Provider; only migrate the UI-facing state
- **Remove old providers** once no screen references them — the compiler will tell you when

## Example

See the [example app](example/) for demos of all features: reactive counter, ViewModelBuilder, multiple observers with a color picker, and a todo list.

## License

MIT
