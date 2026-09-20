import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/network_errors.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Cek apakah list post sudah dimuat di memori
    final postsAsync = ref.watch(postListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Post #$postId'),
      ),
      body: postsAsync.when(
        data: (posts) {
          // Cari post di dalam list
          final existingPost = posts.cast().firstWhere(
                (p) => p.id == postId,
                orElse: () => null,
              );

          // Jika ada di list, langsung tampilkan
          if (existingPost != null) {
            return _buildPostContent(existingPost.title, existingPost.body);
          }

          // Jika tidak ada di list, fetch langsung via postDetailProvider
          return _fetchSinglePost(context, ref);
        },
        loading: () => _fetchSinglePost(context, ref),
        error: (_, _) => _fetchSinglePost(context, ref),
      ),
    );
  }

  Widget _fetchSinglePost(BuildContext context, WidgetRef ref) {
    final singlePostAsync = ref.watch(postDetailProvider(postId));

    return singlePostAsync.when(
      data: (post) => _buildPostContent(post.title, post.body),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(friendlyErrorMessage(err), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(postDetailProvider(postId)),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent(String title, String body) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}