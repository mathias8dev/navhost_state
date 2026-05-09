import 'package:flutter/material.dart';
import 'package:navhost_state/navhost_state.dart';

class _StepperViewModel extends ChangeNotifier {
  final step = 1.obs;
  final total = 0.obs;

  void add() => total.value += step.value;
  void subtract() => total.value -= step.value;

  void setStep(int newStep) => step.value = newStep;
}

class VmBuilderPage extends StatelessWidget {
  const VmBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ViewModelBuilder'),
        backgroundColor: colors.inversePrimary,
      ),
      body: ViewModelBuilder<_StepperViewModel>(
        factory: () => _StepperViewModel(),
        builder: (context, vm, _) => Center(
          child: Obs(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total: ${vm.total.value}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step size: ${vm.step.value}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1')),
                      ButtonSegment(value: 5, label: Text('5')),
                      ButtonSegment(value: 10, label: Text('10')),
                    ],
                    selected: {vm.step.value},
                    onSelectionChanged: (s) => vm.setStep(s.first),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: vm.subtract,
                        icon: const Icon(Icons.remove),
                        label: Text('-${vm.step.value}'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: vm.add,
                        icon: const Icon(Icons.add),
                        label: Text('+${vm.step.value}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'ViewModelBuilder creates the ViewModel\n'
                        'and subscribes to changes in one widget.\n'
                        'Obs() handles fine-grained Rx tracking.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
