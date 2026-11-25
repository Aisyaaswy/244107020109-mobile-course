import '../../../../ai/ai_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';

class AiChatRepositoryImpl implements AiChatRepository {
  final AiService aiService;

  AiChatRepositoryImpl({required this.aiService});

  @override
  Future<String> sendMessage(String text) async {
    return await aiService.ask(text);
  }

  @override
  Future<void> saveApiKey(String key) async {
    await aiService.saveApiKey(key);
  }

  @override
  Future<String?> getApiKey() async {
    return await aiService.getApiKey();
  }

  @override
  Future<void> clearApiKey() async {
    await aiService.clearApiKey();
  }

  @override
  List<ChatMessage> getOfflineFaqAnswers(String query) {
    final q = query.toLowerCase();
    String answer;

    if (q.contains('jadwal') || q.contains('kuliah') || q.contains('kelas')) {
      answer = 'Mode Offline: Jadwal perkuliahan aktif dapat dicek melalui portal SIAKAD Polinema atau menu Pengumuman pada aplikasi ini.';
    } else if (q.contains('uts') || q.contains('uas') || q.contains('ujian')) {
      answer = 'Mode Offline: Jadwal UTS dan UAS ditetapkan sesuai kalender akademik kampus. Pastikan telah memenuhi syarat presensi minimal 80%.';
    } else if (q.contains('catatan') || q.contains('notes')) {
      answer = 'Mode Offline: Anda dapat mencatat materi perkuliahan secara offline di menu Catatan Kampus.';
    } else if (q.contains('dosen') || q.contains('kontak')) {
      answer = 'Mode Offline: Kontak dosen pembimbing dan pengampu dapat dilihat melalui direktori staf pengajar di website resmi kampus.';
    } else {
      answer = 'Mode Offline: Layanan AI sedang tidak dapat dihubungi. Anda tetap dapat mengakses pengumuman dan catatan kampus yang tersimpan di perangkat.';
    }

    return [
      ChatMessage(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        text: answer,
        sender: ChatSender.ai,
        timestamp: DateTime.now(),
        isError: true,
      ),
    ];
  }
}
