import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async {
    try {
      final response = await _dio.get('/announcements');
      final data = response.data as List<dynamic>;
      final list = data
          .map(
            (item) =>
                AnnouncementModel.fromJson(item as Map<String, dynamic>)
                    .toEntity(),
          )
          .toList();
      return (announcements: list, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: NetworkFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }
}
