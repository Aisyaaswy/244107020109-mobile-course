import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note.dart';
import '../../domain/validators/task_title_validator.dart';
import '../providers/notes_providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? validationError;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Tugas / Catatan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('task-title-field'),
                      controller: titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Judul Tugas',
                        hintText: 'Misal: Baca materi Flutter',
                        errorText: validationError,
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setDialogState(() {
                            validationError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('task-body-field'),
                      controller: bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi (opsional)',
                        hintText: 'Detail tugas atau catatan...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  key: const Key('save-task-button'),
                  onPressed: () async {
                    final error = TaskTitleValidator.validate(titleController.text);
                    if (error != null) {
                      setDialogState(() {
                        validationError = error;
                      });
                      return;
                    }

                    await ref.read(addNoteProvider).call(
                      title: titleController.text.trim(),
                      body: bodyController.text.trim(),
                    );
                    ref.invalidate(notesProvider);

                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filteredNotesProvider);
    final query = ref.watch(noteSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan')),
      body: Column(
        children: [
          NoteSearchBar(
            query: query,
            onChanged: (val) {
              ref.read(noteSearchQueryProvider.notifier).setQuery(val);
            },
            onClear: () {
              ref.read(noteSearchQueryProvider.notifier).clear();
            },
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(notesProvider),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return NotesEmptyView(hasQuery: query.trim().isNotEmpty);
                }
                return NotesList(notes: notes);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-task-button'),
        tooltip: 'Tambah Tugas',
        onPressed: () => _showAddTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteSearchBar extends StatefulWidget {
  const NoteSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<NoteSearchBar> createState() => _NoteSearchBarState();
}

class _NoteSearchBarState extends State<NoteSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant NoteSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear();
                  },
                )
              : null,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class NotesEmptyView extends StatelessWidget {
  const NotesEmptyView({super.key, required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off : Icons.note_alt_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery ? 'Catatan tidak ditemukan.' : 'Belum ada catatan.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesList extends StatelessWidget {
  const NotesList({super.key, required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return NoteTileItem(note: notes[index]);
      },
    );
  }
}

/// Ekstraksi widget item catatan dengan const layout
class NoteTileItem extends StatelessWidget {
  const NoteTileItem({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(note.title),
        subtitle: Text(note.body),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
