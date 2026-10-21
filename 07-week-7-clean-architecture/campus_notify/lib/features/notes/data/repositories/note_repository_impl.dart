import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this.openDb});

  final Future<Database> Function() openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();
      return (notes: notes, failure: null);
    } on DatabaseException catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan dari database: $e'),
      );
    } catch (e) {
      // Tangkap error tak terduga lainnya
      return (
        notes: const <Note>[],
        failure: LocalFailure('Terjadi kesalahan tidak terduga: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'notes',
        NoteModel(
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ).toMap(),
      );
      return (
        note: Note(
          id: id,
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ),
        failure: null,
      );
    } on DatabaseException catch (e) {
      return (
        note: null, 
        failure: LocalFailure('Gagal menyimpan catatan ke database: $e'),
      );
    } catch (e) {
      return (
        note: null, 
        failure: LocalFailure('Terjadi kesalahan tidak terduga: $e'),
      );
    }
  }
}

// Fungsi openNotesDb tetap berada di layer Data
Future<Database> openNotesDb() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'notes.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL
        )
      ''');
    },
  );
}