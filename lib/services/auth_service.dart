import '../core/api_client.dart';
import '../core/auth_storage.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  /// 회원가입. 백엔드가 email/password/role 외에 name도 필수로 요구한다
  /// (스웨거 문서에는 빠져 있지만 실제 서버가 400으로 거부함).
  /// Supabase 이메일 인증이 켜져 있어, 가입 직후에는 session이 null로 와서
  /// (`hasSession: false`) 토큰이 발급되지 않는다 — 이메일 인증 후 로그인해야 한다.
  Future<({AppUser user, bool hasSession})> signup({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final response = await _api.post('/api/auth/signup', data: {
      'email': email,
      'password': password,
      'name': name,
      'role': userRoleToString(role),
    });
    final data = response.data as Map<String, dynamic>;
    return _handleAuthResponse(data);
  }

  Future<({AppUser user, bool hasSession})> login({
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

  Future<({AppUser user, bool hasSession})> _handleAuthResponse(Map<String, dynamic> data) async {
    // access_token은 session 아래에 있다 (POST /api/auth/login,signup 응답: {user, session}).
    // session은 이메일 인증 대기 중이면 null.
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
    return (user: user, hasSession: token != null);
  }
}
