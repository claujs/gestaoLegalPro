import 'package:get_it/get_it.dart';
import '../../features/auth/domain/services/auth_service.dart';
import '../../features/auth/infrastructure/services/auth_service_impl.dart';
import '../../features/assistant/domain/services/assistant_service.dart';
import '../../features/assistant/infrastructure/services/assistant_service_impl.dart';
import '../../features/assistant/domain/services/chat_history_service.dart';
import '../../features/assistant/infrastructure/services/chat_history_service_impl.dart';
import '../../features/assistant/domain/services/document_service.dart';
import '../../features/assistant/infrastructure/services/document_service_impl.dart';

final locator = GetIt.instance;

void setupLocator() {
  if (!locator.isRegistered<AuthService>()) {
    locator.registerLazySingleton<AuthService>(() => AuthServiceImpl());
  }
  if (!locator.isRegistered<AssistantService>()) {
    locator.registerLazySingleton<AssistantService>(
      () => AssistantServiceImpl(),
    );
  }
  if (!locator.isRegistered<ChatHistoryService>()) {
    locator.registerLazySingleton<ChatHistoryService>(
      () => ChatHistoryServiceImpl(),
    );
  }
  if (!locator.isRegistered<DocumentService>()) {
    locator.registerLazySingleton<DocumentService>(() => DocumentServiceImpl());
  }
}
