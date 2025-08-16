import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/chat_models.dart';
import '../../domain/services/chat_history_service.dart';

class ChatHistoryServiceImpl implements ChatHistoryService {
  static const String _historyKey = 'chat_history';

  @override
  Future<List<ChatSession>> getSavedChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson == null) return [];

      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.map((json) => ChatSession.fromJson(json)).toList()
        ..sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt),
        ); // Mais recentes primeiro
    } catch (e) {
      print('Erro ao carregar histórico: $e');
      return [];
    }
  }

  @override
  Future<void> saveChat(ChatSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentChats = await getSavedChats();

      // Remove se já existe (para atualizar)
      currentChats.removeWhere((chat) => chat.id == session.id);

      // Adiciona o chat atualizado
      currentChats.insert(0, session);

      // Limita a 20 chats salvos
      if (currentChats.length > 20) {
        currentChats.removeRange(20, currentChats.length);
      }

      final historyJson = jsonEncode(
        currentChats.map((chat) => chat.toJson()).toList(),
      );

      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Erro ao salvar chat: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentChats = await getSavedChats();

      currentChats.removeWhere((chat) => chat.id == chatId);

      final historyJson = jsonEncode(
        currentChats.map((chat) => chat.toJson()).toList(),
      );

      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Erro ao deletar chat: $e');
    }
  }

  @override
  Future<void> clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Erro ao limpar histórico: $e');
    }
  }
}
