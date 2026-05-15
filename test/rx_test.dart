import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('Rx.update', () {
    test('applies updater to current value', () {
      final count = 0.obs;
      count.update((prev) => prev + 1);
      expect(count.value, 1);
    });

    test('chains correctly', () {
      final count = 0.obs;
      count.update((prev) => prev + 1);
      count.update((prev) => prev * 3);
      expect(count.value, 3);
    });

    test('works with list — returns new list', () {
      final items = Rx<List<String>>([]);
      items.update((prev) => [...prev, 'a']);
      items.update((prev) => [...prev, 'b']);
      expect(items.value, ['a', 'b']);
    });

    testWidgets('triggers Obs rebuild', (tester) async {
      final count = 0.obs;

      await tester.pumpWidget(
        MaterialApp(home: Obs(() => Text('${count.value}'))),
      );
      expect(find.text('0'), findsOneWidget);

      count.update((prev) => prev + 5);
      await tester.pump();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('does not rebuild when updater returns same value',
        (tester) async {
      final count = 0.obs;
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
            home: Obs(() {
          builds++;
          return Text('${count.value}');
        })),
      );
      expect(builds, 1);

      count.update((prev) => prev);
      await tester.pump();
      expect(builds, 1);
    });
  });

  group('batch', () {
    testWidgets('multiple Rx changes cause one rebuild', (tester) async {
      final a = 0.obs;
      final b = 0.obs;
      var builds = 0;

      await tester.pumpWidget(MaterialApp(
        home: Obs(() {
          builds++;
          return Text('${a.value}-${b.value}');
        }),
      ));
      expect(builds, 1);

      batch(() {
        a.value = 1;
        b.value = 2;
      });
      await tester.pump();
      expect(builds, 2);
      expect(find.text('1-2'), findsOneWidget);
    });

    testWidgets('nested batches flush only on outermost exit', (tester) async {
      final count = 0.obs;
      var builds = 0;

      await tester.pumpWidget(MaterialApp(
        home: Obs(() {
          builds++;
          return Text('${count.value}');
        }),
      ));
      expect(builds, 1);

      batch(() {
        count.value = 1;
        batch(() {
          count.value = 2;
        });
        count.value = 3;
      });
      await tester.pump();
      expect(builds, 2);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('Rx with complex types', () {
    testWidgets('Rx<List> rebuilds on new list assignment', (tester) async {
      final items = Rx<List<String>>([]);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() {
            builds++;
            return Text('count:${items.value.length}');
          }),
        ),
      );
      expect(builds, 1);
      expect(find.text('count:0'), findsOneWidget);

      items.value = ['a', 'b'];
      await tester.pump();
      expect(builds, 2);
      expect(find.text('count:2'), findsOneWidget);
    });

    testWidgets('Rx<List> does not rebuild on same-reference reassignment',
        (tester) async {
      final items = Rx<List<String>>(['a']);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() {
            builds++;
            return Text('count:${items.value.length}');
          }),
        ),
      );
      expect(builds, 1);

      items.value.add('b');
      items.value = items.value;
      await tester.pump();
      expect(builds, 1);
    });

    testWidgets('Rx<Map> rebuilds on new map assignment', (tester) async {
      final data = Rx<Map<String, int>>({});
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obs(() {
            builds++;
            return Text('keys:${data.value.keys.join(',')}');
          }),
        ),
      );
      expect(builds, 1);

      data.value = {'a': 1, 'b': 2};
      await tester.pump();
      expect(builds, 2);
      expect(find.text('keys:a,b'), findsOneWidget);
    });
  });
}
