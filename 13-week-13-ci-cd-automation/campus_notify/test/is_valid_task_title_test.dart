import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/is_valid_task_title.dart';

void main() {
  group('isValidTaskTitle Unit Tests', () {
    test('menerima judul yang berisi teks normal', () {
      expect(isValidTaskTitle('Belajar Flutter'), isTrue);
      expect(isValidTaskTitle('Kerjakan Praktikum Minggu 12'), isTrue);
    });

    test('menerima teks yang diawali atau diakhiri spasi', () {
      expect(isValidTaskTitle('  Belajar Testing  '), isTrue);
    });

    test('menolak teks kosong atau hanya spasi (kasus kegagalan)', () {
      expect(isValidTaskTitle(''), isFalse);
      expect(isValidTaskTitle(' '), isFalse);
      expect(isValidTaskTitle('   \t\n  '), isFalse);
    });
  });
}
