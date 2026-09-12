import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ToDo & Stats App',
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 153, 206, 236),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}