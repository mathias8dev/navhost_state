import 'package:flutter_test/flutter_test.dart';
import 'package:navhost_state/navhost_state.dart';

void main() {
  group('effect', () {
    test('runs immediately on creation', () {
      final name = 'Alice'.obs;
      final log = <String>[];
      final e = effect(() => log.add(name.value));
      expect(log, ['Alice']);
      e.dispose();
    });

    test('re-runs when dependency changes', () {
      final name = 'Alice'.obs;
      final log = <String>[];
      final e = effect(() => log.add(name.value));
      name.value = 'Bob';
      name.value = 'Carol';
      expect(log, ['Alice', 'Bob', 'Carol']);
      e.dispose();
    });

    test('stops reacting after dispose', () {
      final count = 0.obs;
      var runs = 0;
      final e = effect(() {
        runs++;
        count.value;
      });
      expect(runs, 1);
      e.dispose();
      count.value = 99;
      expect(runs, 1);
    });

    test('tracks conditional dependencies correctly', () {
      final flag = true.obs;
      final a = 'A'.obs;
      final b = 'B'.obs;
      final log = <String>[];

      final e = effect(() => log.add(flag.value ? a.value : b.value));
      expect(log, ['A']);

      a.value = 'A2';
      expect(log, ['A', 'A2']);

      flag.value = false;
      expect(log, ['A', 'A2', 'B']);

      a.value = 'A3'; // no longer tracked
      expect(log, ['A', 'A2', 'B']);

      b.value = 'B2';
      expect(log, ['A', 'A2', 'B', 'B2']);

      e.dispose();
    });
  });
}
