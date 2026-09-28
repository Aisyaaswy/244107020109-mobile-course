import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/prefs.dart';
import 'pages/settings_page.dart'; 
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefsRepo = PrefsRepository();
  await prefsRepo.markOpenedNow();

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau darkModeProvider yang ada di settings_page.dart
    final darkModeAsync = ref.watch(darkModeProvider);

    return darkModeAsync.when(
      data: (isDark) {
        return MaterialApp.router(
          title: 'Offline Notes',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Gagal memuat pengaturan: $err'),
          ),
        ),
      ),
    );
  }
}