import 'package:get/get.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../../core/di/locator.dart';

class AuthController extends GetxController {
  final _authService = locator<AuthService>();
  final isLoading = false.obs;
  final error = RxnString();

  bool get isLoggedIn => _authService.isLoggedIn;

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    error.value = null;
    final ok = await _authService.login(email, password);
    if (!ok) {
      error.value = 'Credenciais inválidas';
    }
    isLoading.value = false;
    return ok;
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
