import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/core/network/token_store.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/main.dart';
import 'package:campus_notify/messaging/push_service.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

class FakeTokenStore implements TokenStore {
  @override
  Future<String?> readAccess() async => 'fake-access-token';

  @override
  Future<String?> readRefresh() async => 'fake-refresh-token';

  @override
  Future<void> save({required String access, required String refresh}) async {}

  @override
  Future<void> clear() async {}
}

class FakeAuthNotifier extends AuthNotifier {
  @override
  Future<bool> build() async => true;
}

class FakeIntegrationPushService implements PushService {
  @override
  Future<void> initialize({required Function(String route) onNavigate}) async {}

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeIntegrationNoteRepository implements NoteRepository {
  final List<Note> _notes = [
    Note(
      id: 1,
      title: 'Tugas Pendahuluan',
      body: 'Persiapan praktikum QA',
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: List<Note>.from(_notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    _notes.add(note);
    return (note: note, failure: null);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'pengguna dapat menavigasi ke halaman catatan dan menambahkan tugas',
    (WidgetTester tester) async {
      final fakeNoteRepo = FakeIntegrationNoteRepository();

      // Jalankan aplikasi dengan Fake Dependencies untuk lingkungan pengujian independen
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pushServiceProvider.overrideWithValue(FakeIntegrationPushService()),
            noteRepositoryProvider.overrideWithValue(fakeNoteRepo),
            notesProvider.overrideWith((ref) async => fakeNoteRepo._notes),
            tokenStoreProvider.overrideWithValue(FakeTokenStore()),
            authStateProvider.overrideWith(FakeAuthNotifier.new),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verifikasi halaman utama terbuka
      expect(find.text('Kampus Notify'), findsOneWidget);

      // 2. Navigasi ke halaman Catatan Kampus melalui IconButton di AppBar
      final notesIcon = find.byTooltip('Catatan Kampus');
      expect(notesIcon, findsOneWidget);
      await tester.tap(notesIcon);
      await tester.pumpAndSettle();

      // 3. Verifikasi halaman Catatan terbuka
      expect(find.text('Catatan'), findsOneWidget);
      expect(find.text('Tugas Pendahuluan'), findsOneWidget);

      // 4. Buka dialog tambah tugas
      final addButton = find.byKey(const Key('add-task-button'));
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 5. Masukkan judul tugas baru pada input form
      final titleField = find.byKey(const Key('task-title-field'));
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'Baca materi');

      // 6. Tekan tombol Simpan
      final saveButton = find.byKey(const Key('save-task-button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 7. Verifikasi tugas baru berhasil tersimpan dan tampil di antarmuka
      expect(
        fakeNoteRepo._notes.any((element) => element.title == 'Baca materi'),
        isTrue,
      );
    },
  );
}
