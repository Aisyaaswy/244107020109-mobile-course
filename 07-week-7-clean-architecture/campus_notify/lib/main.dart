import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import './features/notes/data/repositories/note_repository_impl.dart';
import './features/notes/presentation/providers/notes_providers.dart';
import './features/announcements/presentation/pages/announcement_page.dart';
import './features/announcements/presentation/pages/home_page.dart';
import './features/auth/presentation/pages/login_page.dart';
import './features/auth/presentation/providers/auth_provider.dart';
import './features/notes/presentation/pages/notes_page.dart';
import './messaging/push_service.dart';
import './routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          NoteRepositoryImpl(openDb: openNotesDb),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authStateProvider).value ?? false;

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !loggingIn) return AppRoutes.login;
      if (isLoggedIn && loggingIn) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AnnouncementPage(id: id);
        },
      ),
      GoRoute(
        path: AppRoutes.notes,
        builder: (context, state) => const NotesPage(),
      ),
    ],
  );
});

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      ref
          .read(pushServiceProvider)
          .initialize(
            onNavigate: (route) {
              router.push(route);
            },
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Campus Notification App',
    );
  }
}