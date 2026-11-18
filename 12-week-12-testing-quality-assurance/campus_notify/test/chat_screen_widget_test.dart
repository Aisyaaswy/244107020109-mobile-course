import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/features/chat_screen.dart';
import 'package:campus_notify/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:campus_notify/features/ai_chat/domain/entities/chat_message.dart';
import 'package:campus_notify/features/ai_chat/presentation/providers/ai_chat_provider.dart';

class MockAiChatRepository implements AiChatRepository {
  String? apiKey;
  String? lastSentText;

  @override
  Future<String> sendMessage(String text) async {
    lastSentText = text;
    return 'Halo! Ini respons asisten AI kampus untuk: $text';
  }

  @override
  Future<void> saveApiKey(String key) async {
    apiKey = key;
  }

  @override
  Future<String?> getApiKey() async {
    return apiKey;
  }

  @override
  Future<void> clearApiKey() async {
    apiKey = null;
  }

  @override
  List<ChatMessage> getOfflineFaqAnswers(String query) {
    return [
      ChatMessage(
        id: 'mock_fallback',
        text: 'Mode Offline: fallback info',
        sender: ChatSender.ai,
        timestamp: DateTime.now(),
        isError: true,
      ),
    ];
  }
}

void main() {
  testWidgets('ChatScreen menampilkan judul, pesan sambutan, dan chips rekomendasi', (
    WidgetTester tester,
  ) async {
    final mockRepo = MockAiChatRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi AppBar
    expect(find.text('Asisten AI Kampus'), findsOneWidget);
    expect(find.byIcon(Icons.vpn_key_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    // Verifikasi pesan sambutan awal
    expect(
      find.textContaining('Saya Asisten AI Kampus'),
      findsOneWidget,
    );

    // Verifikasi quick prompt chip
    expect(find.text('📅 Jadwal kuliah semester ini'), findsOneWidget);
    expect(find.text('📝 Tips persiapan ujian UTS/UAS'), findsOneWidget);

    // Verifikasi input textfield dan send icon
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Membuka dialog API Key saat ikon kunci diklik', (
    WidgetTester tester,
  ) async {
    final mockRepo = MockAiChatRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Klik tombol API Key di AppBar
    await tester.tap(find.byTooltip('Pengaturan API Key'));
    await tester.pumpAndSettle();

    // Verifikasi AlertDialog muncul
    expect(find.text('Pengaturan API Key'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('Mengirim pesan menghasilkan bubble pengguna dan respons AI', (
    WidgetTester tester,
  ) async {
    final mockRepo = MockAiChatRepository();
    mockRepo.apiKey = 'active-key';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Ketik pertanyaan di textfield
    await tester.enterText(
      find.byType(TextField),
      'Kapan libur semester ganjil?',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump(); // mulai loading

    expect(find.text('Kapan libur semester ganjil?'), findsOneWidget);

    await tester.pumpAndSettle(); // tunggu respons mock

    expect(
      find.text('Halo! Ini respons asisten AI kampus untuk: Kapan libur semester ganjil?'),
      findsOneWidget,
    );
  });
}

