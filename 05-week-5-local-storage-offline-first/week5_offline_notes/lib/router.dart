import 'package:go_router/go_router.dart';
import 'pages/notes_page.dart';
import 'pages/note_detail_page.dart';
import 'pages/posts_page.dart';
import 'pages/settings_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const NotesPage(),
    ),
    GoRoute(
      path: '/posts',
      builder: (context, state) => const PostsPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    // Rute dengan parameter ID catatan
    GoRoute(
      path: '/note/:id',
      builder: (context, state) {
        final idParam = state.pathParameters['id'];
        final noteId = int.tryParse(idParam ?? '') ?? 0;
        return NoteDetailPage(noteId: noteId);
      },
    ),
  ],
);




