import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/features/ai_chat/data/repositories/ai_chat_repository_impl.dart';

void main() {
  group('AiChatRepositoryImpl Unit Tests', () {
    late AiChatRepositoryImpl repository;

    setUp(() {
      repository = AiChatRepositoryImpl(aiService: AiService());
    });

    test('getOfflineFaqAnswers mengembalikan jawaban jadwal saat offline', () {
      final results = repository.getOfflineFaqAnswers('Bagaimana jadwal kuliah?');
      expect(results.length, 1);
      expect(results.first.text, contains('Jadwal perkuliahan'));
      expect(results.first.isError, isTrue);
    });

    test('getOfflineFaqAnswers mengembalikan jawaban UTS/UAS saat offline', () {
      final results = repository.getOfflineFaqAnswers('Kapan ujian UTS diadakan?');
      expect(results.length, 1);
      expect(results.first.text, contains('Jadwal UTS dan UAS'));
    });

    test('getOfflineFaqAnswers mengembalikan jawaban catatan saat offline', () {
      final results = repository.getOfflineFaqAnswers('Di mana catatan materi?');
      expect(results.length, 1);
      expect(results.first.text, contains('Catatan Kampus'));
    });

    test('getOfflineFaqAnswers mengembalikan default fallback untuk topik umum', () {
      final results = repository.getOfflineFaqAnswers('Berapa harga kopi di kantin?');
      expect(results.length, 1);
      expect(results.first.text, contains('Layanan AI sedang tidak dapat dihubungi'));
    });
  });
}

