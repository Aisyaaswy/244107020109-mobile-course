import '../entities/chat_message.dart';

abstract class AiChatRepository {
  Future<String> sendMessage(String text);
  Future<void> saveApiKey(String key);
  Future<String?> getApiKey();
  Future<void> clearApiKey();
  List<ChatMessage> getOfflineFaqAnswers(String query);
}
