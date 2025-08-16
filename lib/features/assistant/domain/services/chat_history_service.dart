import '../models/chat_models.dart';

abstract class ChatHistoryService {
  Future<List<ChatSession>> getSavedChats();
  Future<void> saveChat(ChatSession session);
  Future<void> deleteChat(String chatId);
  Future<void> clearAllHistory();
}
