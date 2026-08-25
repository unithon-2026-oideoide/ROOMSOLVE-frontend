import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Supabase access token을 기기에 안전하게 저장/조회하는 유틸리티.
class AuthStorage {
  AuthStorage._();

  static final AuthStorage instance = AuthStorage._();

  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _nameKey = 'user_name';
  static const _phoneKey = 'user_phone';
  static const _landlordCodeKey = 'landlord_code';
  static const _linkedLandlordIdKey = 'linked_landlord_id';

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRole(String role) {
    return _storage.write(key: _roleKey, value: role);
  }

  Future<String?> readRole() {
    return _storage.read(key: _roleKey);
  }

  /// 사용자 id가 필요한 API 호출(수리기사 자기 일정 등록 등)을 위해 저장한다.
  Future<void> saveUserId(String userId) {
    return _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> readUserId() {
    return _storage.read(key: _userIdKey);
  }

  /// 백엔드 User 응답에는 email이 없고 name/phone만 있어, 화면에 표시할 값을
  /// 로그인 상태 복원 시에도 쓸 수 있도록 함께 저장한다.
  Future<void> saveName(String? name) {
    if (name == null) return _storage.delete(key: _nameKey);
    return _storage.write(key: _nameKey, value: name);
  }

  Future<String?> readName() {
    return _storage.read(key: _nameKey);
  }

  Future<void> savePhone(String? phone) {
    if (phone == null) return _storage.delete(key: _phoneKey);
    return _storage.write(key: _phoneKey, value: phone);
  }

  Future<String?> readPhone() {
    return _storage.read(key: _phoneKey);
  }

  /// role이 landlord인 사용자만 값이 있다. 세입자가 초대 코드로 연결할 때 보여줄
  /// 필요는 없지만(코드는 임대인 본인만 봄), 앱 재시작 후 계정 정보 화면에서
  /// 다시 보여줄 수 있도록 저장해둔다.
  Future<void> saveLandlordCode(String? code) {
    if (code == null) return _storage.delete(key: _landlordCodeKey);
    return _storage.write(key: _landlordCodeKey, value: code);
  }

  Future<String?> readLandlordCode() {
    return _storage.read(key: _landlordCodeKey);
  }

  /// 세입자가 초대 코드로 연결한 임대인의 id. 앱 재시작 후에도 "임대인 연결"
  /// 화면이 연결 상태를 알 수 있도록 저장해둔다.
  Future<void> saveLinkedLandlordId(String? landlordId) {
    if (landlordId == null) return _storage.delete(key: _linkedLandlordIdKey);
    return _storage.write(key: _linkedLandlordIdKey, value: landlordId);
  }

  Future<String?> readLinkedLandlordId() {
    return _storage.read(key: _linkedLandlordIdKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _landlordCodeKey);
    await _storage.delete(key: _linkedLandlordIdKey);
  }
}
