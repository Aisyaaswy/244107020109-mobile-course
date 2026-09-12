import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // PERBAIKAN: Ubah 'Belum ada tugas' menjadi 'Tidak ada tugas'
    expect(find.text('Tidak ada tugas'), findsOneWidget);

    // Tekan tombol tambah (ikon +)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Ketik teks tugas baru
    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Verifikasi tugas baru muncul di daftar
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}