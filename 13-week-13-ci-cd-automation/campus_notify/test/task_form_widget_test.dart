import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

class MockNoteRepository implements NoteRepository {
  final List<Note> notes = [
    Note(
      id: 1,
      title: 'Catatan Awal',
      body: 'Deskripsi awal',
      updatedAt: DateTime(2026, 11, 18),
    ),
  ];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: List<Note>.from(notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final newNote = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    notes.add(newNote);
    return (note: newNote, failure: null);
  }
}

void main() {
  group('Pengujian Widget Form Tugas & Interaksi Pengguna', () {
    late MockNoteRepository mockRepo;

    setUp(() {
      mockRepo = MockNoteRepository();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(mockRepo),
          notesProvider.overrideWith((ref) async => mockRepo.notes),
        ],
        child: const MaterialApp(home: NotesPage()),
      );
    }

    testWidgets(
      'Tampilan awal: tombol tambah tugas dan daftar tugas awal terlihat',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Memeriksa judul dan catatan awal
        expect(find.text('Catatan'), findsOneWidget);
        expect(find.text('Catatan Awal'), findsOneWidget);

        // Memeriksa tombol tambah tugas dengan Key('add-task-button')
        expect(find.byKey(const Key('add-task-button')), findsOneWidget);
      },
    );

    testWidgets(
      'Masukan tidak valid: menampilkan pesan error saat judul kosong',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Klik tombol tambah tugas untuk membuka modal dialog
        await tester.tap(find.byKey(const Key('add-task-button')));
        await tester.pumpAndSettle();

        // Memeriksa dialog form terbuka
        expect(find.text('Tambah Tugas / Catatan'), findsOneWidget);
        expect(find.byKey(const Key('task-title-field')), findsOneWidget);

        // Langsung tekan tombol Simpan tanpa mengisi judul
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();

        // Memeriksa pesan error validasi muncul
        expect(find.text('Judul tugas tidak boleh kosong'), findsOneWidget);
      },
    );

    testWidgets(
      'Masukan tidak valid: menampilkan pesan error saat judul terlalu pendek (< 3 karakter)',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Buka dialog tambah tugas
        await tester.tap(find.byKey(const Key('add-task-button')));
        await tester.pumpAndSettle();

        // Masukkan judul hanya 2 karakter
        await tester.enterText(find.byKey(const Key('task-title-field')), 'AB');
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();

        // Memeriksa pesan batas minimal karakter
        expect(
          find.text('Judul minimal harus berisi 3 karakter'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tindakan pengguna berhasil: menambahkan tugas dan menutup dialog',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Buka dialog tambah tugas
        await tester.tap(find.byKey(const Key('add-task-button')));
        await tester.pumpAndSettle();

        // Masukkan judul dan deskripsi tugas yang valid
        await tester.enterText(
          find.byKey(const Key('task-title-field')),
          'Baca materi Testing QA',
        );
        await tester.enterText(
          find.byKey(const Key('task-body-field')),
          'Codelab Minggu 12 JTI Polinema',
        );

        // Tekan tombol Simpan
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();

        // Verifikasi dialog telah tertutup
        expect(find.text('Tambah Tugas / Catatan'), findsNothing);

        // Verifikasi tugas baru telah ditambahkan ke dalam repository
        expect(
          mockRepo.notes.any((n) => n.title == 'Baca materi Testing QA'),
          isTrue,
        );
      },
    );
  });
}
