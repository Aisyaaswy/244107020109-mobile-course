import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ai/ai_service.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final service = ref.watch(aiServiceProvider);
  return AiChatRepositoryImpl(aiService: service);
});

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool hasApiKey;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasApiKey = false,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool? hasApiKey,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }
}

class AiChatNotifier extends Notifier<AiChatState> {
  @override
  AiChatState build() {
    _checkApiKey();
    return AiChatState(
      messages: [
        ChatMessage(
          id: 'welcome',
          text: 'Halo! Saya Asisten AI Kampus. Tanyakan apa saja seputar perkuliahan, jadwal, atau ringkasan materi.',
          sender: ChatSender.ai,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> _checkApiKey() async {
    final repo = ref.read(aiChatRepositoryProvider);
    final key = await repo.getApiKey();
    state = state.copyWith(hasApiKey: key != null && key.isNotEmpty);
  }

  Future<void> saveApiKey(String key) async {
    final repo = ref.read(aiChatRepositoryProvider);
    await repo.saveApiKey(key);
    state = state.copyWith(hasApiKey: key.trim().isNotEmpty);
  }

  Future<void> clearApiKey() async {
    final repo = ref.read(aiChatRepositoryProvider);
    await repo.clearApiKey();
    state = state.copyWith(hasApiKey: false);
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      sender: ChatSender.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final repo = ref.read(aiChatRepositoryProvider);
      final reply = await repo.sendMessage(trimmed);

      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: reply,
        sender: ChatSender.ai,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      final repo = ref.read(aiChatRepositoryProvider);
      final fallbackResponses = repo.getOfflineFaqAnswers(trimmed);
      final fallbackText = fallbackResponses.isNotEmpty
          ? fallbackResponses.first.text
          : 'Layanan AI saat ini tidak dapat diakses.';

      final errorMessage = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚠️ $fallbackText',
        sender: ChatSender.ai,
        timestamp: DateTime.now(),
        isError: true,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearChat() {
    state = AiChatState(
      hasApiKey: state.hasApiKey,
      messages: [
        ChatMessage(
          id: 'welcome_reset_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Percakapan telah dibersihkan. Ada yang ingin Anda tanyakan lagi?',
          sender: ChatSender.ai,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
}

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);
