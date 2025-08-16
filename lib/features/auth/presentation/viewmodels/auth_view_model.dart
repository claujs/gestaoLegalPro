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

  Future<bool> sendPasswordReset(String email) async {
    setLoading(true);
    clearError();
    try {
      await _authService.requestPasswordReset(email);
      setLoading(false);
      return true;
    } catch (e) {
      setError('Não foi possível enviar o e-mail. Tente novamente.');
      setLoading(false);
      return false;
    }
  }
}
