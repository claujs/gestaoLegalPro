abstract class AuthService {
  Future<bool> login(String email, String password);
  Future<void> logout();
  bool get isLoggedIn;
}
