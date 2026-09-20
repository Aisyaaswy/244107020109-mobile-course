import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/post.dart';
import 'providers.dart';

class PagedPostsState {
  final List<Post> items;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final Object? error;

  PagedPostsState({
    this.items = const [],
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PagedPostsState copyWith({
    List<Post>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
    Object? error,
  }) {
    return PagedPostsState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

// Gunakan Notifier bawaan Riverpod terbaru
class PagedPostsNotifier extends Notifier<PagedPostsState> {
  static const int _limit = 10;

  @override
  PagedPostsState build() {
    // Inisialisasi state awal & langsung muat halaman pertama
    Future.microtask(() => loadFirstPage());
    return PagedPostsState(isLoading: true);
  }

  Future<void> loadFirstPage() async {
    state = PagedPostsState(isLoading: true);
    try {
      final repo = ref.read(postRepositoryProvider);
      final newPosts = await repo.fetchPostsPage(page: 1, limit: _limit);

      state = PagedPostsState(
        items: newPosts,
        page: 1,
        isLoading: false,
        hasMore: newPosts.length == _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final repo = ref.read(postRepositoryProvider);
      final nextPage = state.page + 1;
      final newPosts = await repo.fetchPostsPage(page: nextPage, limit: _limit);

      state = state.copyWith(
        items: [...state.items, ...newPosts],
        page: nextPage,
        isLoading: false,
        hasMore: newPosts.length == _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

// Ubah penulisan provider menjadi NotifierProvider
final pagedPostsProvider =
    NotifierProvider<PagedPostsNotifier, PagedPostsState>(() {
  return PagedPostsNotifier();
});