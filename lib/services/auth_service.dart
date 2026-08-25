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
  ///
  /// role이 technician이면 businessNumber(사업자등록번호)와 categories(전문 분야,
  /// 최소 1개)가 추가로 필수다 (auth.controller.ts의 vendorSignupError 확인함).
  Future<({AppUser user, bool hasSession})> signup({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? businessNumber,
    List<String>? categories,
  }) async {
    final response = await _api.post('/api/auth/signup', data: {
      'email': email,
      'password': password,
      'name': name,
      'role': userRoleToString(role),
      if (role == UserRole.technician) 'business_number': businessNumber,
      if (role == UserRole.technician) 'categories': categories,
    });
    final data = response.data as Map<String, dynamic>;
    return _handleAuthResponse(data, fallbackEmail: email);
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
    return _handleAuthResponse(data, fallbackEmail: email);
  }

  /// PATCH /api/users/link-landlord — 임대인 초대 코드로 현재 로그인한 사용자를
  /// 연결한다. 성공하면 서버가 채운 linked_landlord_id를 로컬에도 반영한다.
  Future<AppUser> linkLandlord(String code) async {
    final response = await _api.patch('/api/users/link-landlord', data: {'code': code});
    final data = response.data as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] ?? data);
    await AuthStorage.instance.saveLinkedLandlordId(user.linkedLandlordId);
    return user;
  }

  Future<void> logout() async {
    await AuthStorage.instance.clear();
  }

  Future<({AppUser user, bool hasSession})> _handleAuthResponse(
    Map<String, dynamic> data, {
    required String fallbackEmail,
  }) async {
    // access_token은 session 아래에 있다 (POST /api/auth/login,signup 응답: {user, session}).
    // session은 이메일 인증 대기 중이면 null.
    final session = data['session'] as Map<String, dynamic>?;
    final token = session?['access_token'] ?? data['access_token'] ?? data['accessToken'];
    if (token != null) {
      await AuthStorage.instance.saveAccessToken(token.toString());
    }
    // vendor는 user와 형제 키다(data['vendor'], data['user'] 안이 아님) — role이
    // technician일 때만 signup/login 둘 다 내려준다. AppUser.fromJson은 data['user']만
    // 받아 vendor를 모르므로, 여기서 꺼내 copyWith로 붙인다.
    final vendor = data['vendor'] as Map<String, dynamic>?;
    var user = AppUser.fromJson(data['user'] ?? data).copyWith(vendorId: vendor?['id']?.toString());
    // 백엔드 User 응답에는 email이 없다(Supabase Auth 세션 쪽에만 있음) — 로그인/가입
    // 폼에 입력한 값을 그대로 채워 계정 정보 화면에 표시할 수 있게 한다.
    if (user.email.isEmpty) {
      user = AppUser(
        id: user.id,
        email: fallbackEmail,
        name: user.name,
        phone: user.phone,
        createdAt: user.createdAt,
        role: user.role,
        landlordCode: user.landlordCode,
        linkedLandlordId: user.linkedLandlordId,
        vendorId: user.vendorId,
      );
    }
    await _persistUser(user);
    return (user: user, hasSession: token != null);
  }

  Future<void> _persistUser(AppUser user) async {
    await AuthStorage.instance.saveRole(userRoleToString(user.role));
    await AuthStorage.instance.saveUserId(user.id);
    await AuthStorage.instance.saveName(user.name);
    await AuthStorage.instance.savePhone(user.phone);
    await AuthStorage.instance.saveEmail(user.email);
    await AuthStorage.instance.saveCreatedAt(user.createdAt);
    await AuthStorage.instance.saveLandlordCode(user.landlordCode);
    await AuthStorage.instance.saveLinkedLandlordId(user.linkedLandlordId);
    await AuthStorage.instance.saveVendorId(user.vendorId);
  }
}
