import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  final Future<Database> Function()? openDb;

  NoteRepository({this.openDb});

  Future<Database> _getDb() async {
    if (openDb != null) {
      return await openDb!();
    }
    return await openNotesDb();
  }

  /// Membaca semua catatan dari database lokal
  Future<List<Note>> fetchNotes() async {
    final db = await _getDb();
    final maps = await db.query('notes', orderBy: 'updated_at DESC');
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// Menambah catatan baru
  Future<int> addNote({required String title, String body = ''}) async {
    final db = await _getDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    return await db.insert('notes', note.toMap());
  }

  /// Menghapus catatan
  Future<int> deleteNote(int id) async {
    final db = await _getDb();
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Menghitung jumlah catatan dirty
  Future<int> countDirty() async {
    final db = await _getDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM notes WHERE dirty = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Membaca satu catatan spesifik berdasarkan ID
  Future<Note?> getNoteById(int id) async {
    final db = await _getDb();
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }
}

// Provider Utama
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.fetchNotes();
});

final dirtyCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.countDirty();
});

final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.getNoteById(id);
});