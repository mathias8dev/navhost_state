import 'package:flutter/material.dart';
import 'package:navhost/navhost.dart';
import 'package:navhost_state/navhost_state.dart';

class CounterViewModel extends ChangeNotifier {
  final count = 0.obs;

  void increment() => count.value++;
  void decrement() => count.value--;
  void reset() => count.value = 0;
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.viewModel(() => CounterViewModel());
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reactive Counter'),
        backgroundColor: colors.inversePrimary,
      ),
      body: Center(
        child: Obs(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${vm.count.value}',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Using .obs + Obs()',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: vm.decrement,
                      icon: const Icon(Icons.remove),
                      label: const Text('Dec'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: vm.reset,
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: vm.increment,
                      icon: const Icon(Icons.add),
                      label: const Text('Inc'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Navigate away and come back — the count is preserved.\n'
                      'Pop this page — the ViewModel is disposed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.navController.navigate('/multi-observer'),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Navigate away (state kept)'),
                ),
              ],
            )),
      ),
    );
  }
}
