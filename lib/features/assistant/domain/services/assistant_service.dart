import '../models/chat_models.dart';

abstract class AssistantService {
  Future<ChatResponse> sendMessage(ChatRequest request);
  Future<ChatResponse> sendPlainText(String text);
  void cancelCurrentRequest();
}
