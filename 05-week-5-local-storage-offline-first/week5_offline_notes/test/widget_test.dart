import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/widgets/note_tile.dart';

void main() {
  testWidgets('NoteTile menampilkan judul dan indicator dirty saat dirty == true',
      (WidgetTester tester) async {
    final note = Note(
      title: 'Catatan Tes',
      body: 'Isi catatan tes',
      updatedAt: DateTime.now(),
      dirty: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteTile(
            note: note,
            onDelete: () {},
          ),
        ),
      ),
    );

    // Verifikasi teks judul tampil
    expect(find.text('Catatan Tes'), findsOneWidget);

    // Verifikasi teks indikator 'Belum tersinkron' atau ikon sync tampil
    expect(find.text('Belum tersinkron'), findsOneWidget);
  });
}