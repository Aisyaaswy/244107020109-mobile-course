import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/usecases/search_notes.dart';

void main() {
  group('SearchNotes Use Case Tests', () {
    final list = [
      Note(
        id: 1,
        title: 'Belanja Mingguan',
        body: 'Sayur, buah, susu',
        updatedAt: DateTime(2026, 10, 20),
      ),
      Note(
        id: 2,
        title: 'Tugas Mobile Week 9',
        body: 'Mengerjakan codelab AI',
        updatedAt: DateTime(2026, 10, 21),
      ),
      Note(
        id: 3,
        title: 'Daftar BELANJA Elektronik',
        body: 'Kabel USB-C, Mouse',
        updatedAt: DateTime(2026, 10, 22),
      ),
      Note(
        id: 4,
        title: 'Rapat Organisasi',
        body: 'Bahas proker divisi',
        updatedAt: DateTime(2026, 10, 23),
      ),
    ];

    const searchNotes = SearchNotes();

    test('query kosong mengembalikan semua catatan', () {
      final result = searchNotes(list, '');
      expect(result.length, equals(4));
    });

    test('filter abaikan huruf besar/kecil', () {
      // Catatan dengan kata 'belanja' ada 2:
      // 1. 'Belanja Mingguan' (Kapital di awal)
      // 3. 'Daftar BELANJA Elektronik' (Huruf kapital semua)
      final result = searchNotes(list, 'belanja');
      expect(result, hasLength(2));
    });

    test('query tak cocok kembalikan kosong', () {
      final result = searchNotes(list, 'zzz tak ada');
      expect(result, isEmpty);
    });

    test('query dengan spasi di awal/akhir tetap bekerja (trimming)', () {
      final result = searchNotes(list, '  tugas  ');
      expect(result, hasLength(1));
      expect(result.first.title, contains('Tugas Mobile'));
    });
  });
}

