import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/task_service.dart';

/// Implementasi FakeTaskRepository sesuai Codelab Minggu 12 Bab 4
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    List<String>? initialTasks,
    this.error,
  }) : _tasks = initialTasks != null ? List<String>.from(initialTasks) : [];

  final List<String> _tasks;
  final Exception? error;

  @override
  Future<List<String>> getTasks() async {
    if (error != null) {
      throw error!;
    }
    return List.unmodifiable(_tasks);
  }

  @override
  Future<bool> addTask(String title) async {
    if (error != null) {
      throw error!;
    }
    _tasks.add(title);
    return true;
  }
}

void main() {
  group('Pengujian Asinkron dan Dependensi dengan Fake Repository', () {
    test('loadTasks mengembalikan daftar tugas saat repository sukses', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(
        initialTasks: ['Belajar Widget Test', 'Menyusun Laporan Praktikum'],
      );
      final service = TaskService(fakeRepo);

      // Act
      final result = await service.loadTasks();

      // Assert
      expect(result.length, 2);
      expect(result.first, 'Belajar Widget Test');
      expect(result.last, 'Menyusun Laporan Praktikum');
    });

    test('loadTasks melempar exception saat repository mengalami galat (error handling)', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(
        error: Exception('Gagal menghubungi server database kampus'),
      );
      final service = TaskService(fakeRepo);

      // Act & Assert
      expect(
        () => service.loadTasks(),
        throwsA(isA<Exception>()),
      );
    });

    test('addNewTask berhasil menambahkan tugas baru ke repository', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(initialTasks: ['Tugas 1']);
      final service = TaskService(fakeRepo);

      // Act
      final success = await service.addNewTask('Tugas 2: Testing & QA');
      final updatedList = await service.loadTasks();

      // Assert
      expect(success, isTrue);
      expect(updatedList.length, 2);
      expect(updatedList.contains('Tugas 2: Testing & QA'), isTrue);
    });

    test('addNewTask melempar ArgumentError jika input judul kosong', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository();
      final service = TaskService(fakeRepo);

      // Act & Assert
      expect(
        () => service.addNewTask('   '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
