import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navhost_state/navhost_state.dart';

void main() {
  group('computed', () {
    test('initial value is derived from dependencies', () {
      final a = 2.obs;
      final b = 3.obs;
      final sum = computed(() => a.value + b.value);
      expect(sum.value, 5);
    });

    test('updates when dependency changes', () {
      final a = 2.obs;
      final b = 3.obs;
      final sum = computed(() => a.value + b.value);
      a.value = 10;
      expect(sum.value, 13);
    });

    test('does not recompute when unrelated Rx changes', () {
      final a = 1.obs;
      final unrelated = 99.obs;
      var computeCount = 0;
      final doubled = computed(() {
        computeCount++;
        return a.value * 2;
      });

      expect(doubled.value, 2);
      expect(computeCount, 1);
      unrelated.value = 100;
      expect(computeCount, 1);
    });

    test('throws on direct assignment', () {
      final c = computed(() => 42);
      expect(() => c.value = 0, throwsUnsupportedError);
    });

    testWidgets('Obs rebuilds when computed value changes', (tester) async {
      final base = 1.obs;
      final doubled = computed(() => base.value * 2);

      await tester.pumpWidget(MaterialApp(
        home: Obs(() => Text('${doubled.value}')),
      ));
      expect(find.text('2'), findsOneWidget);

      base.value = 5;
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
    });

    test('chained computed values update transitively', () {
      final x = 1.obs;
      final doubled = computed(() => x.value * 2);
      final quadrupled = computed(() => doubled.value * 2);

      expect(quadrupled.value, 4);
      x.value = 3;
      expect(quadrupled.value, 12);
    });
  });
}
