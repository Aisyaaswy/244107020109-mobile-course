import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;

  const NoteTile({
    super.key,
    required this.note,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (note.id != null) {
          context.push('/note/${note.id}');
        }
      },
      title: Text(
        note.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.body.isNotEmpty)
            Text(
              note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (note.dirty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync_problem,
                  size: 14,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  'Belum tersinkron',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: onDelete,
      ),
    );
  }
}