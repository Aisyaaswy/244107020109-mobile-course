import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// 1. MODEL DATA
// ============================================================================
/// Class sederhana untuk merepresentasikan data statistik.
class StatItem {
  final String title;
  final String value;
  final IconData icon;

  const StatItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

// ============================================================================
// 2. ASYNC NOTIFIER & PROVIDER
// ============================================================================
/// Notifier yang mengelola state asinkron untuk data statistik.
/// Menggunakan [AsyncNotifier] agar secara otomatis menangani AsyncValue
/// (AsyncData, AsyncLoading, AsyncError).
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  // Random generator untuk simulasi kemungkinan error 30%
  final Random _random;

  /// Constructor menerima [Random] opsional agar mempermudah testing (Dependency Injection).
  StatsNotifier([Random? random]) : _random = random ?? Random();

  @override
  Future<List<StatItem>> build() async {
    // Memanggil fungsi fetch saat provider pertama kali diinisialisasi
    return _fetchStats();
  }

  /// Fungsi private untuk mensimulasikan pengambilan data dari API / Database.
  Future<List<StatItem>> _fetchStats() async {
    // Simulasi delay jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi kegagalan dengan peluang 30% (_random.nextDouble() < 0.3)
    if (_random.nextDouble() < 0.3) {

      throw Exception('Gagal memuat data statistik dari server.');
    }

    // Mengembalikan 3 item data statistik jika sukses
    return const [
      StatItem(
        title: 'Total Pengguna',
        value: '1,250',
        icon: Icons.people,
      ),
      StatItem(
        title: 'Pendapatan Bulan Ini',
        value: 'Rp 15.400.000',
        icon: Icons.attach_money,
      ),
      StatItem(
        title: 'Tugas Selesai',
        value: '94%',
        icon: Icons.check_circle_outline,
      ),
    ];
  }

  /// Fungsi untuk me-refresh data saat tombol retry ditekan.
  Future<void> refresh() async {
    // Mengubah state menjadi AsyncLoading agar UI menampilkan spinner saat memuat ulang
    state = const AsyncLoading();

    // AsyncValue.guard secara otomatis menangkap exception (jika ada) 
    // dan mengubah state menjadi AsyncError tanpa butuh try-catch manual.
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

/// Provider global yang menyediakan [StatsNotifier] dan state-nya.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);

// ============================================================================
// 3. UI WIDGET (CONSUMERWIDGET)
// ============================================================================
/// Halaman utama statistik yang membaca state dari [statsProvider].
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca state asinkron dari statsProvider dan mendengarkan perubahannya
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aplikasi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Tombol refresh di AppBar untuk memuat ulang data secara manual
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(statsProvider.notifier).refresh(),
          ),
        ],
      ),
      // Penanganan 3 kondisi AsyncValue (Loading, Error, Success) menggunakan .when()
      body: statsAsync.when(
        // --------------------------------------------------------------------
        // KONDISI 1: LOADING
        // --------------------------------------------------------------------
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data statistik...'),
            ],
          ),
        ),

        // --------------------------------------------------------------------
        // KONDISI 2: ERROR
        // --------------------------------------------------------------------
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Terjadi Kesalahan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                // Tombol Retry untuk mencoba memuat data kembali
                FilledButton.icon(
                  onPressed: () => ref.read(statsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),

        // --------------------------------------------------------------------
        // KONDISI 3: SUCCESS (DATA READY)
        // --------------------------------------------------------------------
        data: (statsList) => ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: statsList.length,
          itemBuilder: (context, index) {
            final item = statsList[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    item.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}