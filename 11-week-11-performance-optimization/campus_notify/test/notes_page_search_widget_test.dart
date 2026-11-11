import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

void main() {
  final sampleNotes = [
    Note(
      id: 1,
      title: 'Belanja Mingguan',
      body: 'Susu, telur, roti',
      updatedAt: DateTime(2026, 10, 1),
    ),
    Note(
      id: 2,
      title: 'Tugas Mobile Week 9',
      body: 'AI-assisted development',
      updatedAt: DateTime(2026, 10, 2),
    ),
    Note(
      id: 3,
      title: 'Daftar BELANJA Elektronik',
      body: 'Mouse dan keyboard',
      updatedAt: DateTime(2026, 10, 3),
    ),
  ];

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [notesProvider.overrideWith((ref) async => sampleNotes)],
      child: const MaterialApp(home: NotesPage()),
    );
  }

  testWidgets('NotesPage menampilkan search bar dan semua catatan awal', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Belanja Mingguan'), findsOneWidget);
    expect(find.text('Tugas Mobile Week 9'), findsOneWidget);
    expect(find.text('Daftar BELANJA Elektronik'), findsOneWidget);
  });

  testWidgets(
    'NotesPage filter case-insensitive saat user mengetik di search bar',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Cari dengan huruf kecil 'belanja'
      await tester.enterText(find.byType(TextField), 'belanja');
      await tester.pumpAndSettle();

      // Seharusnya muncul 2 catatan yang memuat 'belanja' / 'BELANJA'
      expect(find.text('Belanja Mingguan'), findsOneWidget);
      expect(find.text('Daftar BELANJA Elektronik'), findsOneWidget);
      expect(find.text('Tugas Mobile Week 9'), findsNothing);
    },
  );

  testWidgets('NotesPage menampilkan empty state saat pencarian tidak cocok', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Cari query yang tidak ada
    await tester.enterText(find.byType(TextField), 'zzz tak ada');
    await tester.pumpAndSettle();

    expect(find.text('Catatan tidak ditemukan.'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('NotesPage tombol clear mengembalikan seluruh catatan', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'belanja');
    await tester.pumpAndSettle();
    expect(find.text('Tugas Mobile Week 9'), findsNothing);

    // Tekan tombol clear (ikon X)
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    // Seluruh catatan kembali terlihat
    expect(find.text('Tugas Mobile Week 9'), findsOneWidget);
    expect(find.text('Belanja Mingguan'), findsOneWidget);
  });
}
