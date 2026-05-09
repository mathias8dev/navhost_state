import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navhost/navhost.dart';
import 'package:navhost_state/navhost_state.dart';

void main() {
  group('Rx', () {
    test('.obs creates Rx wrapper', () {
      final count = 0.obs;
      expect(count.value, 0);
    });

    test('setting value updates it', () {
      final count = 0.obs;
      count.value = 5;
      expect(count.value, 5);
    });

    test('toString shows value', () {
      final count = 42.obs;
      expect(count.toString(), 'Rx(42)');
    });
  });

  group('Obs widget', () {
    testWidgets('rebuilds when Rx value changes', (tester) async {
      final count = 0.obs;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(
              () => Text('${count.value}', textDirection: TextDirection.ltr)),
        ),
      );
      expect(find.text('0'), findsOneWidget);

      count.value = 1;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('does not rebuild when unrelated Rx changes', (tester) async {
      final count = 0.obs;
      final unrelated = 0.obs;
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() {
            buildCount++;
            return Text('${count.value}', textDirection: TextDirection.ltr);
          }),
        ),
      );
      expect(buildCount, 1);

      unrelated.value = 99;
      await tester.pump();
      expect(buildCount, 1);
    });

    testWidgets('re-tracks dependencies on conditional reads', (tester) async {
      final show = true.obs;
      final count = 0.obs;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() => Text(
                show.value ? 'count:${count.value}' : 'hidden',
                textDirection: TextDirection.ltr,
              )),
        ),
      );
      expect(find.text('count:0'), findsOneWidget);

      count.value = 5;
      await tester.pump();
      expect(find.text('count:5'), findsOneWidget);

      show.value = false;
      await tester.pump();
      expect(find.text('hidden'), findsOneWidget);

      var buildAfterHide = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() {
            buildAfterHide++;
            return Text(
              show.value ? 'count:${count.value}' : 'hidden',
              textDirection: TextDirection.ltr,
            );
          }),
        ),
      );
      buildAfterHide = 0;

      count.value = 10;
      await tester.pump();
      expect(buildAfterHide, 0);
    });

    testWidgets('nested Obs track independently', (tester) async {
      final outer = 'A'.obs;
      final inner = 'X'.obs;
      var outerBuilds = 0;
      var innerBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() {
            outerBuilds++;
            return Column(children: [
              Text('outer:${outer.value}'),
              Obs(() {
                innerBuilds++;
                return Text('inner:${inner.value}');
              }),
            ]);
          }),
        ),
      );
      expect(outerBuilds, 1);
      expect(innerBuilds, 1);

      inner.value = 'Y';
      await tester.pump();
      expect(outerBuilds, 1);
      expect(innerBuilds, 2);

      outer.value = 'B';
      await tester.pump();
      expect(outerBuilds, 2);
    });

    testWidgets('same value assignment does not rebuild', (tester) async {
      final count = 0.obs;
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() {
            builds++;
            return Text('${count.value}');
          }),
        ),
      );
      expect(builds, 1);

      count.value = 0;
      await tester.pump();
      expect(builds, 1);
    });

    testWidgets('multiple Obs watching the same Rx all rebuild',
        (tester) async {
      final count = 0.obs;
      var buildsA = 0;
      var buildsB = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(children: [
            Obs(() {
              buildsA++;
              return Text('A:${count.value}');
            }),
            Obs(() {
              buildsB++;
              return Text('B:${count.value}');
            }),
          ]),
        ),
      );
      expect(buildsA, 1);
      expect(buildsB, 1);
      expect(find.text('A:0'), findsOneWidget);
      expect(find.text('B:0'), findsOneWidget);

      count.value = 7;
      await tester.pump();
      expect(buildsA, 2);
      expect(buildsB, 2);
      expect(find.text('A:7'), findsOneWidget);
      expect(find.text('B:7'), findsOneWidget);
    });

    testWidgets('removed Obs stops listening', (tester) async {
      final show = true.obs;
      final count = 0.obs;
      var innerBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() => show.value
              ? Obs(() {
                  innerBuilds++;
                  return Text('count:${count.value}');
                })
              : const Text('gone')),
        ),
      );
      expect(innerBuilds, 1);

      // Remove the inner Obs from the tree
      show.value = false;
      await tester.pump();
      expect(find.text('gone'), findsOneWidget);
      innerBuilds = 0;

      // Changing count should not cause errors or rebuild the removed Obs
      count.value = 42;
      await tester.pump();
      expect(innerBuilds, 0);
    });

    testWidgets('rapid successive changes apply correctly', (tester) async {
      final count = 0.obs;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() => Text('${count.value}')),
        ),
      );
      expect(find.text('0'), findsOneWidget);

      count.value = 1;
      count.value = 2;
      count.value = 3;
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Obs reading multiple Rx values rebuilds on any change',
        (tester) async {
      final first = 'A'.obs;
      final second = 'B'.obs;
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() {
            builds++;
            return Text('${first.value}-${second.value}');
          }),
        ),
      );
      expect(builds, 1);
      expect(find.text('A-B'), findsOneWidget);

      first.value = 'X';
      await tester.pump();
      expect(builds, 2);
      expect(find.text('X-B'), findsOneWidget);

      second.value = 'Y';
      await tester.pump();
      expect(builds, 3);
      expect(find.text('X-Y'), findsOneWidget);
    });

    testWidgets('Rx with nullable type', (tester) async {
      final name = Rx<String?>(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() => Text(name.value ?? 'none')),
        ),
      );
      expect(find.text('none'), findsOneWidget);

      name.value = 'Alice';
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);

      name.value = null;
      await tester.pump();
      expect(find.text('none'), findsOneWidget);
    });

    testWidgets('global Rx shared across multiple routes', (tester) async {
      final shared = 0.obs;

      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute(
              '/',
              (_) => Obs(() => Text('home:${shared.value}'))),
          NavRoute(
              '/other',
              (_) => Obs(() => Text('other:${shared.value}'))),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();
      expect(find.text('home:0'), findsOneWidget);

      shared.value = 5;
      await tester.pump();
      expect(find.text('home:5'), findsOneWidget);

      nav.navigate('/other');
      await tester.pumpAndSettle();
      expect(find.text('other:5'), findsOneWidget);

      shared.value = 10;
      await tester.pump();
      expect(find.text('other:10'), findsOneWidget);
    });
  });

  group('Scoped ViewModel', () {
    testWidgets('viewModel returns same instance across rebuilds',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute(
              '/',
              (_) => Builder(builder: (context) {
                    final vm = context.viewModel(() => _TestViewModel());
                    return Text('count:${vm.count}');
                  })),
          NavRoute('/b', (_) => const Text('B')),
        ]),
      );
      _TestViewModel.reset();
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);
      expect(_TestViewModel.instanceCount, 1);

      nav.notifyListeners();
      await tester.pumpAndSettle();
      expect(_TestViewModel.instanceCount, 1);
    });

    testWidgets('pop disposes the viewModel', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (_) => const Text('Home')),
          NavRoute(
              '/detail',
              (_) => Builder(builder: (context) {
                    final vm = context.viewModel(() => _TestViewModel());
                    return Text('count:${vm.count}');
                  })),
        ]),
      );
      _TestViewModel.reset();
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/detail');
      await tester.pumpAndSettle();
      expect(_TestViewModel.instanceCount, 1);
      expect(_TestViewModel.disposeCount, 0);

      nav.pop();
      await tester.pumpAndSettle();
      expect(_TestViewModel.disposeCount, 1);
    });

    testWidgets('navigate with replace disposes all viewModels',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute(
              '/',
              (_) => Builder(builder: (context) {
                    context.viewModel(() => _TestViewModel());
                    return const Text('Home');
                  })),
          NavRoute(
              '/a',
              (_) => Builder(builder: (context) {
                    context.viewModel(() => _TestViewModel());
                    return const Text('A');
                  })),
          NavRoute('/b', (_) => const Text('B')),
        ]),
      );
      _TestViewModel.reset();
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();
      nav.navigate('/a');
      await tester.pumpAndSettle();
      expect(_TestViewModel.instanceCount, 2);

      nav.navigate('/b', replace: true);
      await tester.pumpAndSettle();
      expect(_TestViewModel.disposeCount, 2);
    });

    testWidgets('same type on different routes yields separate instances',
        (tester) async {
      late _TestViewModel homeVm;
      late _TestViewModel detailVm;
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute(
              '/',
              (_) => Builder(builder: (context) {
                    homeVm = context.viewModel(() => _TestViewModel());
                    return const Text('Home');
                  })),
          NavRoute(
              '/detail',
              (_) => Builder(builder: (context) {
                    detailVm = context.viewModel(() => _TestViewModel());
                    return const Text('Detail');
                  })),
        ]),
      );
      _TestViewModel.reset();
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/detail');
      await tester.pumpAndSettle();

      expect(_TestViewModel.instanceCount, 2);
      expect(identical(homeVm, detailVm), false);
    });

    testWidgets('popUntil disposes intermediate viewModels', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (_) => const Text('Home')),
          NavRoute(
              '/a',
              (_) => Builder(builder: (context) {
                    context.viewModel(() => _TestViewModel());
                    return const Text('A');
                  })),
          NavRoute(
              '/b',
              (_) => Builder(builder: (context) {
                    context.viewModel(() => _TestViewModel());
                    return const Text('B');
                  })),
          NavRoute(
              '/c',
              (_) => Builder(builder: (context) {
                    context.viewModel(() => _TestViewModel());
                    return const Text('C');
                  })),
        ]),
      );
      _TestViewModel.reset();
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/a');
      nav.navigate('/b');
      nav.navigate('/c');
      await tester.pumpAndSettle();
      expect(_TestViewModel.instanceCount, 3);

      nav.popUntil('/');
      await tester.pumpAndSettle();
      expect(_TestViewModel.disposeCount, 3);
    });

    testWidgets('ViewModelBuilder creates and listens to viewModel',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute(
            '/',
            (_) => ViewModelBuilder<_TestViewModel>(
              factory: () => _TestViewModel(),
              builder: (context, vm, child) => Column(children: [
                Text('count:${vm.count}'),
                ElevatedButton(
                  onPressed: vm.increment,
                  child: const Text('inc'),
                ),
              ]),
            ),
          ),
        ]),
      );
      _TestViewModel.reset();
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);

      await tester.tap(find.text('inc'));
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('manual ViewModelScope works without rxRoutes',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: [
          NavRoute(
            '/',
            (_) => ViewModelScope(
              child: Builder(builder: (context) {
                final vm = context.viewModel(() => _TestViewModel());
                return Text('count:${vm.count}');
              }),
            ),
          ),
        ],
      );
      _TestViewModel.reset();
      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);
      expect(_TestViewModel.instanceCount, 1);
    });
  });

  group('Plain class ViewModel (no ChangeNotifier)', () {
    testWidgets('works with context.viewModel and Obs', (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute(
              '/',
              (_) => Builder(builder: (context) {
                    final vm = context.viewModel(() => _PlainViewModel());
                    return Obs(() => Text('count:${vm.count.value}'));
                  })),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);

      _PlainViewModel.lastInstance!.increment();
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('same instance reused across rebuilds', (tester) async {
      _PlainViewModel.instanceCount = 0;
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute(
              '/',
              (_) => Builder(builder: (context) {
                    final vm = context.viewModel(() => _PlainViewModel());
                    return Obs(() => Text('count:${vm.count.value}'));
                  })),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();
      expect(_PlainViewModel.instanceCount, 1);

      nav.notifyListeners();
      await tester.pumpAndSettle();
      expect(_PlainViewModel.instanceCount, 1);
    });

    testWidgets('does not crash on dispose (no dispose method)',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute('/', (_) => const Text('Home')),
          NavRoute(
              '/detail',
              (_) => Builder(builder: (context) {
                    context.viewModel(() => _PlainViewModel());
                    return const Text('Detail');
                  })),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();

      nav.navigate('/detail');
      await tester.pumpAndSettle();

      // Pop should not throw — plain objects are just dropped
      nav.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('Obs + viewModel integration', () {
    testWidgets('Obs rebuilds on Rx change inside scoped ViewModel',
        (tester) async {
      final nav = NavController(
        initialRoute: '/',
        routes: rxRoutes([
          NavRoute(
              '/',
              (_) => Builder(builder: (context) {
                    final vm = context.viewModel(() => _CounterViewModel());
                    return Obs(() => Text('count:${vm.count.value}'));
                  })),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(home: NavHost(navController: nav)),
      );
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);

      _CounterViewModel.lastInstance!.increment();
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
    });
  });
}

class _TestViewModel extends ChangeNotifier {
  static int instanceCount = 0;
  static int disposeCount = 0;

  static void reset() {
    instanceCount = 0;
    disposeCount = 0;
  }

  int count = 0;

  _TestViewModel() {
    instanceCount++;
  }

  void increment() {
    count++;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeCount++;
    super.dispose();
  }
}

class _PlainViewModel {
  static _PlainViewModel? lastInstance;
  static int instanceCount = 0;

  final count = 0.obs;

  _PlainViewModel() {
    lastInstance = this;
    instanceCount++;
  }

  void increment() => count.value++;
}

class _CounterViewModel extends ChangeNotifier {
  static _CounterViewModel? lastInstance;

  final count = 0.obs;

  _CounterViewModel() {
    lastInstance = this;
  }

  void increment() => count.value++;
}
