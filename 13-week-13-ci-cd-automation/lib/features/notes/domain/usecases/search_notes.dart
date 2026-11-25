import '../entities/note.dart';

/// Use case murni untuk melakukan penyaringan catatan berdasarkan judul.
/// Bebas dari dependensi framework Flutter, Dio, maupun SQLite.
class SearchNotes {
  const SearchNotes();

  /// Menyaring daftar [notes] berdasarkan [query] judul catatan secara case-insensitive
  /// dan mengabaikan kelebihan spasi di awal/akhir.
  List<Note> call(List<Note> notes, String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return notes;
    return notes
        .where((note) => note.title.toLowerCase().contains(trimmedQuery))
        .toList();
  }
}
