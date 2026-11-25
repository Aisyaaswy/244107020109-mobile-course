import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

/// Implementasi AnnouncementRepository dengan strategi caching Stale-While-Revalidate
/// Sesuai materi Codelab Minggu 11 Bab 6: Optimasi Jaringan dan Caching
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._dio, {List<Announcement>? initialCache})
    : _cachedAnnouncements = initialCache ?? [];

  final Dio _dio;
  List<Announcement> _cachedAnnouncements;
  DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Status validitas cache dalam memori
  bool get isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < _cacheTtl;

  /// Akses read-only ke daftar pengumuman di cache
  List<Announcement> get cachedAnnouncements =>
      List.unmodifiable(_cachedAnnouncements);

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements({bool forceRefresh = false}) async {
    // 1. Stale-While-Revalidate: Jika cache ada dan valid serta tidak forceRefresh,
    // langsung kembalikan data cache secara instan (0ms frame latency)
    if (!forceRefresh && isCacheValid && _cachedAnnouncements.isNotEmpty) {
      return (announcements: _cachedAnnouncements, failure: null);
    }

    // 2. Fetch fresh data dari network/API di background
    try {
      final response = await _dio.get('/announcements');
      final data = response.data as List<dynamic>;
      final fresh = data
          .map(
            (item) =>
                AnnouncementModel.fromJson(item as Map<String, dynamic>)
                    .toEntity(),
          )
          .toList();

      // 3. Update memory cache & timestamp
      _cachedAnnouncements = fresh;
      _lastFetchTime = DateTime.now();

      return (announcements: fresh, failure: null);
    } catch (e) {
      // 4. Offline Fallback / Stale-While-Revalidate Graceful Degradation:
      // Jika jaringan gagal, gunakan data cache lokal yang sudah tersimpan
      if (_cachedAnnouncements.isNotEmpty) {
        return (announcements: _cachedAnnouncements, failure: null);
      }
      return (
        announcements: const <Announcement>[],
        failure: NetworkFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  /// Tambahan method untuk kebutuhan lazy loading / pagination
  Future<List<Announcement>> fetchPage({
    required int page,
    int pageSize = 10,
  }) async {
    // Jika ada cache lokal, slice berdasarkan pagination
    if (_cachedAnnouncements.isNotEmpty) {
      final startIndex = (page - 1) * pageSize;
      if (startIndex >= _cachedAnnouncements.length) {
        return <Announcement>[];
      }
      final endIndex = (startIndex + pageSize).clamp(
        0,
        _cachedAnnouncements.length,
      );
      return _cachedAnnouncements.sublist(startIndex, endIndex);
    }

    final result = await getAnnouncements();
    final all = result.announcements;
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= all.length) {
      return <Announcement>[];
    }
    final endIndex = (startIndex + pageSize).clamp(0, all.length);
    return all.sublist(startIndex, endIndex);
  }
}
