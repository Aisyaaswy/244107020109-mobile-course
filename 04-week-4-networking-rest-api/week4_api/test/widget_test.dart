import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/paged_posts.dart';
import 'package:week4_api/pages/paged_post_page.dart';

class FakePagedPostsNotifier extends PagedPostsNotifier {
  @override
  PagedPostsState build() {
    return const PagedPostsState();
  }
}

void main() {
  // 1. Test render UI
  testWidgets('PagedPostPage dapat dirender tanpa error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pagedPostsProvider.overrideWith(() => FakePagedPostsNotifier()),
        ],
        child: const MaterialApp(
          home: PagedPostPage(),
        ),
      ),
    );

    expect(find.text('Posts Paged'), findsOneWidget);
  });

  // 2. Unit Test: Kasus field hilang
  test('fromJson harus menangani json dengan field yang hilang tanpa crash', () {
    final Map<String, dynamic> incompleteJson = {
      'postId': 1,
      'id': 101,
    };

    final comment = Comment.fromJson(incompleteJson);

    expect(comment.postId, equals(1));
    expect(comment.id, equals(101));
    expect(comment.name, equals(''));
    expect(comment.email, equals(''));
    expect(comment.body, equals(''));
  });

  // 3. Unit Test: Edge Case Tambahan (Tipe data tidak sesuai/mismatched)
  test('fromJson aman saat menerima tipe data yang salah (mismatched type)', () {
    final Map<String, dynamic> wrongTypeJson = {
      'postId': 'bukan_integer',
      'id': null,
      'name': 12345,
      'email': true,
      'body': null,
    };

    final comment = Comment.fromJson(wrongTypeJson);

    expect(comment.postId, equals(0));
    expect(comment.id, equals(0));
    expect(comment.name, equals(''));
    expect(comment.email, equals(''));
    expect(comment.body, equals(''));
  });
}