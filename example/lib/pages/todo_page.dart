import 'package:flutter/material.dart';
import 'package:navhost_state/navhost_state.dart';

class _Todo {
  final String title;
  final bool done;
  const _Todo(this.title, {this.done = false});
  _Todo copyWith({bool? done}) => _Todo(title, done: done ?? this.done);
}

class _TodoViewModel extends ChangeNotifier {
  final todos = <_Todo>[].obs;
  final filter = _Filter.all.obs;

  List<_Todo> get filtered {
    final list = todos.value;
    switch (filter.value) {
      case _Filter.all:
        return list;
      case _Filter.active:
        return list.where((t) => !t.done).toList();
      case _Filter.done:
        return list.where((t) => t.done).toList();
    }
  }

  int get doneCount => todos.value.where((t) => t.done).length;

  void add(String title) {
    todos.value = [...todos.value, _Todo(title)];
  }

  void toggle(int index) {
    final list = [...todos.value];
    list[index] = list[index].copyWith(done: !list[index].done);
    todos.value = list;
  }

  void remove(int index) {
    final list = [...todos.value];
    list.removeAt(index);
    todos.value = list;
  }

  void clearDone() {
    todos.value = todos.value.where((t) => !t.done).toList();
  }
}

enum _Filter { all, active, done }

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.viewModel(() => _TodoViewModel());
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        backgroundColor: colors.inversePrimary,
        actions: [
          Obs(() => vm.doneCount > 0
              ? TextButton(
                  onPressed: vm.clearDone,
                  child: const Text('Clear done'),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Obs(() => SegmentedButton<_Filter>(
                  segments: [
                    ButtonSegment(
                      value: _Filter.all,
                      label: Text('All (${vm.todos.value.length})'),
                    ),
                    ButtonSegment(
                      value: _Filter.active,
                      label: Text(
                          'Active (${vm.todos.value.length - vm.doneCount})'),
                    ),
                    ButtonSegment(
                      value: _Filter.done,
                      label: Text('Done (${vm.doneCount})'),
                    ),
                  ],
                  selected: {vm.filter.value},
                  onSelectionChanged: (s) => vm.filter.value = s.first,
                )),
          ),
          Expanded(
            child: Obs(() {
              final items = vm.filtered;
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    vm.todos.value.isEmpty
                        ? 'No todos yet — tap + to add one'
                        : 'No matching todos',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                );
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final todo = items[i];
                  final realIndex = vm.todos.value.indexOf(todo);
                  return ListTile(
                    leading: Checkbox(
                      value: todo.done,
                      onChanged: (_) => vm.toggle(realIndex),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration:
                            todo.done ? TextDecoration.lineThrough : null,
                        color: todo.done ? colors.onSurfaceVariant : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => vm.remove(realIndex),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, vm),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, _TodoViewModel vm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Todo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'What needs doing?'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              vm.add(value.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                vm.add(text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
