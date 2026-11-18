/// Kontrak TaskRepository sesuai Codelab Minggu 12 Bab 4
abstract interface class TaskRepository {
  Future<List<String>> getTasks();
  Future<bool> addTask(String title);
}

/// Service untuk memproses logika tugas dengan dependensi terabstraksi
class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }

  Future<bool> addNewTask(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Judul tugas tidak boleh kosong');
    }
    return _repository.addTask(title.trim());
  }
}
