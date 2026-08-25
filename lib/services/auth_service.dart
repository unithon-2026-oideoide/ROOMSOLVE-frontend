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
    await AuthStorage.instance.saveUserId(user.id);
    await AuthStorage.instance.saveName(user.name);
    await AuthStorage.instance.savePhone(user.phone);
    return user;
  }

  Future<void> logout() async {
    await AuthStorage.instance.clear();
  }

  Future<AppUser> _handleAuthResponse(Map<String, dynamic> data) async {
    // access_token은 session 아래에 있다 (POST /api/auth/login,signup 응답: {user, session}).
    final session = data['session'] as Map<String, dynamic>?;
    final token = session?['access_token'] ?? data['access_token'] ?? data['accessToken'];
    if (token != null) {
      await AuthStorage.instance.saveAccessToken(token.toString());
    }
    final user = AppUser.fromJson(data['user'] ?? data);
    await AuthStorage.instance.saveRole(userRoleToString(user.role));
    await AuthStorage.instance.saveUserId(user.id);
    await AuthStorage.instance.saveName(user.name);
    await AuthStorage.instance.savePhone(user.phone);
    return user;
  }
}
