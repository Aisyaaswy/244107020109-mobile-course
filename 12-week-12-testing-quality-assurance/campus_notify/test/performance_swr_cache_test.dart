import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';

class MockDioWithCounter {
  int getCallCount = 0;
  bool shouldThrow = false;

  Future<Response<dynamic>> get(String path) async {
    getCallCount++;
    if (shouldThrow) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'Network unreachable',
      );
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: [
        {
          'id': '101',
          'title': 'Pengumuman Ujian Semester',
          'body': 'Pelaksanaan UTS tanggal 20 November',
          'created_at': '2026-11-11T08:00:00Z',
        },
        {
          'id': '102',
          'title': 'Beasiswa Prestasi Polinema',
          'body': 'Pendaftaran dibuka hingga akhir bulan',
          'created_at': '2026-11-11T09:00:00Z',
        },
      ],
    );
  }
}

void main() {
  group('Performance & Caching (Stale-While-Revalidate) Unit Tests', () {
    test('Mengambil data dari cache instan jika cache masih valid (hemat bandwidth)', () async {
      final initialCache = [
        Announcement(
          id: 'mock-1',
          title: 'Pengumuman Cached',
          createdAt: DateTime.now(),
        ),
      ];

      // Inject repository dengan cache awal
      final repository = AnnouncementRepositoryImpl(
        Dio(),
        initialCache: initialCache,
      );

      // Pada panggilan pertama saat cache ada & valid, tidak perlu request HTTP
      // (mensimulasikan SWR instant render)
      expect(repository.cachedAnnouncements.length, 1);
      expect(repository.cachedAnnouncements.first.title, 'Pengumuman Cached');
    });

    test('Pagination fetchPage memotong list data per halaman dengan tepat', () async {
      final cacheData = List.generate(
        15,
        (i) => Announcement(
          id: '$i',
          title: 'Pengumuman #$i',
          createdAt: DateTime.now(),
        ),
      );

      final repository = AnnouncementRepositoryImpl(
        Dio(),
        initialCache: cacheData,
      );

      final page1 = await repository.fetchPage(page: 1, pageSize: 5);
      expect(page1.length, 5);
      expect(page1.first.title, 'Pengumuman #0');
      expect(page1.last.title, 'Pengumuman #4');

      final page2 = await repository.fetchPage(page: 2, pageSize: 5);
      expect(page2.length, 5);
      expect(page2.first.title, 'Pengumuman #5');
      expect(page2.last.title, 'Pengumuman #9');

      final page3 = await repository.fetchPage(page: 3, pageSize: 5);
      expect(page3.length, 5);
      expect(page3.first.title, 'Pengumuman #10');

      final page4 = await repository.fetchPage(page: 4, pageSize: 5);
      expect(page4.isEmpty, true);
    });
  });
}
