import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/auth_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// 로그인 상태와 현재 사용자 role을 앱 전역에서 관리한다.
/// go_router의 redirect 로직이 이 provider를 참조한다.
class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isInitialized = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  UserRole get role => _currentUser?.role ?? UserRole.unknown;

  /// 앱 시작 시 저장된 토큰이 있는지 확인해 로그인 상태를 복원한다.
  /// 저장소 접근이 실패해도(예: 플랫폼 채널 미지원 환경) 앱이 멈추지 않도록
  /// 로그인 안 된 상태로 취급하고 계속 진행한다.
  Future<void> restoreSession() async {
    try {
      final token = await AuthStorage.instance.readAccessToken();
      final roleString = await AuthStorage.instance.readRole();
      if (token != null && token.isNotEmpty) {
        final id = await AuthStorage.instance.readUserId();
        final name = await AuthStorage.instance.readName();
        final phone = await AuthStorage.instance.readPhone();
        _currentUser = AppUser(
          id: id ?? '',
          email: '',
          name: name,
          phone: phone,
          role: userRoleFromString(roleString),
        );
      }
    } catch (_) {
      _currentUser = null;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final user = await AuthService.instance.login(email: email, password: password);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> signup({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final user = await AuthService.instance.signup(email: email, password: password, role: role);
    _currentUser = user;
    notifyListeners();
  }

  /// 사용자 유형 변경 화면에서 호출된다. PATCH /api/users/{id}/role를 호출해
  /// 서버에 반영한 뒤 로컬 상태를 갱신한다.
  Future<void> updateRole(UserRole role) async {
    final current = _currentUser;
    if (current == null || current.id.isEmpty) {
      throw ApiException('사용자 정보를 확인할 수 없습니다. 다시 로그인해주세요.');
    }
    final user = await AuthService.instance.updateRole(userId: current.id, role: role);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _currentUser = null;
    notifyListeners();
  }
}
