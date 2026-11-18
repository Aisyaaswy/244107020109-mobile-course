import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';

/// Provider kontrak repositori catatan
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  throw UnimplementedError(
    'noteRepositoryProvider harus di-override di ProviderScope main.dart',
  );
});

/// Provider use case GetNotes
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

/// Provider use case AddNote
final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

/// Provider use case SearchNotes (Domain Layer - Pure Use Case)
final searchNotesProvider = Provider<SearchNotes>((ref) {
  return const SearchNotes();
});

/// Notifier untuk state string query pencarian (Riverpod 3.x compatible)
class NoteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

/// Provider state query pencarian menggunakan NotifierProvider (Riverpod 3.x)
final noteSearchQueryProvider =
    NotifierProvider<NoteSearchQueryNotifier, String>(
      NoteSearchQueryNotifier.new,
    );

/// Provider utama untuk mengambil catatan dari repository (Async data)
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.notes;
});

/// Provider presentation terfilter: menggabungkan data catatan dengan use case search
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(noteSearchQueryProvider);
  final searchUseCase = ref.watch(searchNotesProvider);

  return notesAsync.whenData((notes) => searchUseCase(notes, query));
});
