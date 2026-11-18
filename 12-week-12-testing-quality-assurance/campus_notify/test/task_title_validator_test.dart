import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/notes/domain/validators/task_title_validator.dart';

void main() {
  group('TaskTitleValidator Business Logic & Edge Cases', () {
    // Skenario 1: Kasus Sukses
    group('Kasus Sukses', () {
      test('menerima judul tugas yang valid dan memenuhi batas panjang', () {
        expect(TaskTitleValidator.isValid('Selesaikan Laporan Mobile'), isTrue);
        expect(TaskTitleValidator.validate('Selesaikan Laporan Mobile'), isNull);
      });

      test('menerima judul dengan spasi berlebih setelah dipangkas', () {
        expect(TaskTitleValidator.isValid('   Praktikum Minggu 12   '), isTrue);
        expect(TaskTitleValidator.validate('   Praktikum Minggu 12   '), isNull);
      });
    });

    // Skenario 2: Kasus Tepi (Edge Cases)
    group('Kasus Tepi (Edge Cases)', () {
      test('menerima judul dengan tepat panjang minimum 3 karakter', () {
        expect(TaskTitleValidator.isValid('UTS'), isTrue);
        expect(TaskTitleValidator.validate('UTS'), isNull);
      });

      test('menolak judul dengan 2 karakter (satu karakter di bawah batas minimum)', () {
        expect(TaskTitleValidator.isValid('AB'), isFalse);
        expect(
          TaskTitleValidator.validate('AB'),
          'Judul minimal harus berisi 3 karakter',
        );
      });

      test('menerima judul tepat panjang maksimum 100 karakter', () {
        final exact100 = 'A' * 100;
        expect(TaskTitleValidator.isValid(exact100), isTrue);
        expect(TaskTitleValidator.validate(exact100), isNull);
      });

      test('menolak judul melebihi panjang maksimum (101 karakter)', () {
        final over100 = 'A' * 101;
        expect(TaskTitleValidator.isValid(over100), isFalse);
        expect(
          TaskTitleValidator.validate(over100),
          'Judul maksimal berisi 100 karakter',
        );
      });
    });

    // Skenario 3: Kasus Kegagalan (Failure Cases)
    group('Kasus Kegagalan (Failure Cases)', () {
      test('menolak input null', () {
        expect(TaskTitleValidator.isValid(null), isFalse);
        expect(
          TaskTitleValidator.validate(null),
          'Judul tugas tidak boleh kosong',
        );
      });

      test('menolak string kosong', () {
        expect(TaskTitleValidator.isValid(''), isFalse);
        expect(
          TaskTitleValidator.validate(''),
          'Judul tugas tidak boleh kosong',
        );
      });

      test('menolak string yang hanya berisi spasi, tab, atau baris baru', () {
        expect(TaskTitleValidator.isValid('   \t  \n  '), isFalse);
        expect(
          TaskTitleValidator.validate('   \t  \n  '),
          'Judul tugas tidak boleh kosong',
        );
      });
    });
  });
}
