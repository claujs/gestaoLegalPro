import 'package:get_it/get_it.dart';
import '../../features/auth/domain/services/auth_service.dart';
import '../../features/auth/infrastructure/services/auth_service_impl.dart';

final locator = GetIt.instance;

void setupLocator() {
  if (locator.isRegistered<AuthService>()) return;
  locator.registerLazySingleton<AuthService>(() => AuthServiceImpl());
}
