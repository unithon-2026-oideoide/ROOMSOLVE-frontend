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
        final email = await AuthStorage.instance.readEmail();
        final createdAt = await AuthStorage.instance.readCreatedAt();
        final landlordCode = await AuthStorage.instance.readLandlordCode();
        final linkedLandlordId = await AuthStorage.instance.readLinkedLandlordId();
        final vendorId = await AuthStorage.instance.readVendorId();
        _currentUser = AppUser(
          id: id ?? '',
          email: email ?? '',
          name: name,
          phone: phone,
          createdAt: createdAt,
          role: userRoleFromString(roleString),
          landlordCode: landlordCode,
          linkedLandlordId: linkedLandlordId,
          vendorId: vendorId,
        );
      }
    } catch (_) {
      _currentUser = null;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final result = await AuthService.instance.login(email: email, password: password);
    // 로그인은 세션이 없으면 백엔드가 401(예: "Email not confirmed")로 이미 거부하므로
    // 여기 도달했다면 항상 세션이 있다.
    _currentUser = result.user;
    notifyListeners();
  }

  /// 회원가입. 이메일 인증이 필요한 계정이면(session이 null) 로그인 상태로
  /// 취급하지 않고 예외를 던진다 — 화면에서 "이메일을 확인해주세요" 안내로 쓰인다.
  ///
  /// role이 technician이면 businessNumber/categories가 추가로 필요하다.
  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? businessNumber,
    List<String>? categories,
  }) async {
    final result = await AuthService.instance.signup(
      email: email,
      password: password,
      name: name,
      role: role,
      businessNumber: businessNumber,
      categories: categories,
    );
    if (!result.hasSession) {
      throw ApiException('가입 확인 이메일을 보냈습니다. 메일함에서 인증 링크를 확인한 뒤 로그인해주세요.');
    }
    _currentUser = result.user;
    notifyListeners();
  }

  /// 임대인 초대 코드로 현재 로그인한 사용자를 연결한다(설정 > 임대인 연결,
  /// 또는 세입자 회원가입 시 선택 입력). 응답에는 users row 전체가 오지만,
  /// 로그인 세션에만 있는 email 등을 잃지 않도록 linkedLandlordId만 갈아끼운다.
  Future<void> linkLandlord(String code) async {
    final updated = await AuthService.instance.linkLandlord(code);
    _currentUser = _currentUser?.copyWith(linkedLandlordId: updated.linkedLandlordId) ?? updated;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _currentUser = null;
    notifyListeners();
  }
}
