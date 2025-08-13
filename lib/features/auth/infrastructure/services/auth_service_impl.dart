import '../../domain/services/auth_service.dart';

class AuthServiceImpl implements AuthService {
  String? _token;
  static const _mockEmail = 'admin@demo.com';
  static const _mockSenha = '123456';

  @override
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (email == _mockEmail && password == _mockSenha) {
      _token = 'fake-token';
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    _token = null;
  }

  @override
  bool get isLoggedIn => _token != null;
}
