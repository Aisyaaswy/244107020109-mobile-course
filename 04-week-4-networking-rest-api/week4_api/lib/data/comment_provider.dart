import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';
import 'network_errors.dart';

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(createDio()),
);

// Paling simpel & anti-error untuk fetch data berparameter (postId)
final commentsProvider = FutureProvider.family<List<Comment>, int>((ref, postId) async {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.fetchComments(postId);
});
