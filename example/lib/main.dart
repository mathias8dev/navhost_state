import 'package:flutter/material.dart';
import 'package:navhost/navhost.dart';
import 'package:navhost_state/navhost_state.dart';

import 'pages/counter_page.dart';
import 'pages/multi_observer_page.dart';
import 'pages/showcase_page.dart';
import 'pages/todo_page.dart';
import 'pages/vm_builder_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navController = NavController(
    routes: rxRoutes([
      NavRoute('/', (_, _) => const ShowcasePage()),
      NavRoute('/counter', (_, _) => const CounterPage()),
      NavRoute('/vm-builder', (_, _) => const VmBuilderPage()),
      NavRoute('/multi-observer', (_, _) => const MultiObserverPage()),
      NavRoute('/todo', (_, _) => const TodoPage()),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'navhost_state Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: NavHost(navController: _navController),
    );
  }
}
