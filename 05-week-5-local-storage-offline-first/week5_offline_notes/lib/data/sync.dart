import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'local/db.dart';
import 'local/post.dart';

class SyncService {
  final Dio _dio;

  SyncService({Dio? dio}) : _dio = dio ?? Dio();

  /// Memuat data posts dengan strategi Cache-First
  Future<List<Post>> loadPostsCacheFirst({
    Function()? onRefreshed,
    bool forceOffline = false,
  }) async {
    final cached = await readCachedPosts();

    if (forceOffline) {
      return cached;
    }

    _fetchAndCachePosts(onRefreshed);

    return cached;
  }

  /// Membaca data posts dari database lokal SQLite
  Future<List<Post>> readCachedPosts() async {
    final db = await openNotesDb();
    final maps = await db.query('cached_posts');

    return maps.map((map) {
      final payload = jsonDecode(map['payload'] as String);
      return Post.fromMap(payload as Map<String, dynamic>);
    }).toList();
  }

  /// Menyimpan daftar posts ke cache SQLite
  Future<void> savePostsToCache(List<Post> posts) async {
    final db = await openNotesDb();
    final batch = db.batch();

    batch.delete('cached_posts');
    final now = DateTime.now().toIso8601String();
    for (final post in posts) {
      batch.insert(
        'cached_posts',
        {
          'id': post.id,
          'payload': jsonEncode(post.toMap()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Mengambil data posts dari API dan memperbarui cache
  Future<void> _fetchAndCachePosts(Function()? onRefreshed) async {
    try {
      final response = await _dio.get('https://jsonplaceholder.typicode.com/posts');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final posts = data.map((json) => Post.fromMap(json as Map<String, dynamic>)).toList();

        await savePostsToCache(posts);
        if (onRefreshed != null) onRefreshed();
      }
    } catch (_) {
      // Mengabaikan error jaringan agar UI tetap menampilkan cache saat offline
    }
  }

  /// Menandai semua catatan lokal yang dirty menjadi tersinkron (dirty = 0)
  Future<int> syncDirtyNotes() async {
    final db = await openNotesDb();
    
    // Hitung jumlah data dirty sebelum diupdate
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM notes WHERE dirty = 1',
    );
    final countDirty = Sqflite.firstIntValue(countResult) ?? 0;

    if (countDirty > 0) {
      await db.update(
        'notes',
        {'dirty': 0},
        where: 'dirty = ?',
        whereArgs: [1],
      );
    }

    return countDirty;
  }
}