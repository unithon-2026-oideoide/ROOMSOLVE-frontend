import '../core/api_client.dart';
import '../core/auth_storage.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  Future<AppUser> signup({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final response = await _api.post('/api/auth/signup', data: {
      'email': email,
      'password': password,
      'role': userRoleToString(role),
    });
    final data = response.data as Map<String, dynamic>;
    return _handleAuthResponse(data);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    return _handleAuthResponse(data);
  }

  Future<AppUser> updateRole({
    required String userId,
    required UserRole role,
  }) async {
    final response = await _api.patch('/api/users/$userId/role', data: {
      'role': userRoleToString(role),
    });
    final data = response.data as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] ?? data);
    await AuthStorage.instance.saveRole(userRoleToString(user.role));
    return user;
  }

  Future<void> logout() async {
    await AuthStorage.instance.clear();
  }

  Future<AppUser> _handleAuthResponse(Map<String, dynamic> data) async {
    final token = data['access_token'] ?? data['accessToken'];
    if (token != null) {
      await AuthStorage.instance.saveAccessToken(token.toString());
    }
    final user = AppUser.fromJson(data['user'] ?? data);
    await AuthStorage.instance.saveRole(userRoleToString(user.role));
    return user;
  }
}
