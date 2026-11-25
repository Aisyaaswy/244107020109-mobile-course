import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../messaging/push_service.dart';
import '../../../../routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Halaman Utama Kampus Notify yang telah dioptimasi performanya:
/// 1. Lazy Loading & Pagination (Infinite Scroll) menggunakan ListView.builder
/// 2. RepaintBoundary untuk mengisolasi repaint pada AI Banner & list items
/// 3. Ekstraksi Widget ke class terpisah dengan const constructor
/// 4. Manajemen memori (dispose ScrollController)
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _announcements = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    ref.read(pushServiceProvider).subscribeToTopic('pengumuman-kampus');
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Listener infinite scroll (Lazy loading saat mendekati 200px dari dasar)
  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _announcements.clear();
      _page = 1;
      _hasMore = true;
    });

    // Simulasi dataset pengumuman kampus berhalaman
    final initialBatch = _generatePageItems(1);
    if (mounted) {
      setState(() {
        _announcements.addAll(initialBatch);
        _isLoading = false;
        _page = 2;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    // Simulasi latensi pagination
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    if (_page > 3) {
      // Dibatasi sampai page 3 sebagai demo batas halaman
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }

    final newItems = _generatePageItems(_page);
    setState(() {
      _announcements.addAll(newItems);
      _page++;
      _isLoading = false;
      if (newItems.isEmpty) {
        _hasMore = false;
      }
    });
  }

  List<Map<String, String>> _generatePageItems(int page) {
    if (page == 1) {
      return const [
        {'id': '1', 'title': 'Pengumuman'},
        {'id': '2', 'title': 'Jadwal Kuliah Semester Ganjil 2026/2027'},
        {'id': '3', 'title': 'Panduan Pelaksanaan Ujian Tengah Semester'},
      ];
    } else if (page == 2) {
      return const [
        {'id': '4', 'title': 'Pendaftaran Beasiswa Unggulan Mahasiswa'},
        {'id': '5', 'title': 'Workshop Optimasi Performa Aplikasi Mobile'},
        {'id': '6', 'title': 'Kalender Libur Nasional & Akademik'},
      ];
    } else if (page == 3) {
      return const [
        {'id': '7', 'title': 'Pembaruan Fasilitas Laboratorium TI'},
        {'id': '8', 'title': 'Perekrutan Asisten Dosen Mata Kuliah Mobile'},
      ];
    }
    return const [];
  }

  void _navigateToNotes() {
    context.push(AppRoutes.notes);
  }

  void _navigateToAiChat() {
    context.push(AppRoutes.aiChat);
  }

  Future<void> _handleLogout() async {
    await ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampus Notify'),
        actions: [
          IconButton(
            tooltip: 'Catatan Kampus',
            icon: const Icon(Icons.note_alt_outlined),
            onPressed: _navigateToNotes,
          ),
          IconButton(
            tooltip: 'Tanya AI Kampus',
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: _navigateToAiChat,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Fitur AI Asisten dibungkus RepaintBoundary untuk mengisolasi
            // proses repaint gradient dan box shadow yang berat saat list di-scroll
            RepaintBoundary(child: AiAssistantBanner(onTap: _navigateToAiChat)),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Daftar Pengumuman Kampus',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount:
                    _announcements.length + (_hasMore && _isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _announcements.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final item = _announcements[index];
                  return AnnouncementItemTile(
                    id: item['id']!,
                    title: item['title']!,
                    onTap: () {
                      context.push(AppRoutes.announcementDetail(item['id']!));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAiChat,
        icon: const Icon(Icons.chat),
        label: const Text('Tanya AI'),
      ),
    );
  }
}

/// Ekstraksi Widget Banner AI Asisten dengan RepaintBoundary & const child
class AiAssistantBanner extends StatelessWidget {
  const AiAssistantBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade600, Colors.deepPurple.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.smart_toy, color: Colors.indigo),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Assistant Kampus',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tanya jadwal, tips ujian, atau ringkas catatan',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ekstraksi Widget Tile Pengumuman dengan const sub-elements
class AnnouncementItemTile extends StatelessWidget {
  const AnnouncementItemTile({
    super.key,
    required this.id,
    required this.title,
    required this.onTap,
  });

  final String id;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.campaign)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
