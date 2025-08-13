import '../../domain/services/auth_service.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/controllers/base_view_model.dart';

class AuthViewModel extends BaseViewModel {
  final _authService = locator<AuthService>();

  bool get isLoggedIn => _authService.isLoggedIn;

  Future<bool> login(String email, String password) async {
    setLoading(true);
    clearError();
    final ok = await _authService.login(email, password);
    if (!ok) {
      setError('Credenciais inválidas');
    }
    setLoading(false);
    return ok;
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
