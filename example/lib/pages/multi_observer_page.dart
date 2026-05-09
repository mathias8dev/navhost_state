import 'package:flutter/material.dart';
import 'package:navhost_state/navhost_state.dart';

class _ColorViewModel extends ChangeNotifier {
  final red = 128.obs;
  final green = 128.obs;
  final blue = 128.obs;
}

class MultiObserverPage extends StatelessWidget {
  const MultiObserverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.viewModel(() => _ColorViewModel());
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Observers'),
        backgroundColor: colors.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Observer 1: Color preview — watches all three
          Obs(() => Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Color.fromARGB(
                      255, vm.red.value, vm.green.value, vm.blue.value),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'RGB(${vm.red.value}, ${vm.green.value}, ${vm.blue.value})',
                  style: TextStyle(
                    color: _contrastColor(
                        vm.red.value, vm.green.value, vm.blue.value),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              )),
          const SizedBox(height: 24),

          // Observer 2: Red slider — only watches red
          _ColorSlider(
            label: 'Red',
            rx: vm.red,
            activeColor: Colors.red,
          ),

          // Observer 3: Green slider — only watches green
          _ColorSlider(
            label: 'Green',
            rx: vm.green,
            activeColor: Colors.green,
          ),

          // Observer 4: Blue slider — only watches blue
          _ColorSlider(
            label: 'Blue',
            rx: vm.blue,
            activeColor: Colors.blue,
          ),

          const SizedBox(height: 16),

          // Observer 5: Hex code — watches all three
          Obs(() => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _toHex(vm.red.value, vm.green.value, vm.blue.value),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Each slider is an independent Obs that only rebuilds\n'
                'when its tracked Rx value changes. The preview and\n'
                'hex code watch all three and rebuild on any change.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _contrastColor(int r, int g, int b) {
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  static String _toHex(int r, int g, int b) {
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}

class _ColorSlider extends StatelessWidget {
  final String label;
  final Rx<int> rx;
  final Color activeColor;

  const _ColorSlider({
    required this.label,
    required this.rx,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obs(() => Row(
          children: [
            SizedBox(width: 50, child: Text(label)),
            Expanded(
              child: Slider(
                value: rx.value.toDouble(),
                min: 0,
                max: 255,
                activeColor: activeColor,
                onChanged: (v) => rx.value = v.round(),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${rx.value}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ));
  }
}
