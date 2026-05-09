import 'package:flutter/material.dart';
import 'package:navhost/navhost.dart';

class ShowcasePage extends StatelessWidget {
  const ShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.navController;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('navhost_state'),
        backgroundColor: colors.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoTile(
            icon: Icons.touch_app,
            title: 'Reactive Counter (.obs + Obs)',
            subtitle: 'context.viewModel() with .obs reactive values '
                'and Obs auto-tracking widget',
            onTap: () => nav.navigate('/counter'),
          ),
          _DemoTile(
            icon: Icons.auto_awesome,
            title: 'ViewModelBuilder',
            subtitle: 'Convenience widget that creates a scoped ViewModel '
                'and rebuilds automatically',
            onTap: () => nav.navigate('/vm-builder'),
          ),
          _DemoTile(
            icon: Icons.visibility,
            title: 'Multiple Observers',
            subtitle: 'Multiple Obs widgets watching the same Rx values '
                '— all rebuild independently',
            onTap: () => nav.navigate('/multi-observer'),
          ),
          _DemoTile(
            icon: Icons.checklist,
            title: 'Todo List',
            subtitle: 'More complex state management with a list of items, '
                'add/remove/toggle operations',
            onTap: () => nav.navigate('/todo'),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DemoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
