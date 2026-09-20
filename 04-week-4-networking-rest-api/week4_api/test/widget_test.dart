import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/paged_posts.dart';
import 'package:week4_api/pages/paged_post_page.dart';

// Notifier tiruan untuk mencegah pemicuan koneksi jaringan
class FakePagedPostsNotifier extends PagedPostsNotifier {
  @override
  PagedPostsState build() {
    return PagedPostsState();
  }
}

void main() {
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
}