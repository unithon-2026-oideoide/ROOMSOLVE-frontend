enum UserRole { tenant, landlord, technician, unknown }

UserRole userRoleFromString(String? value) {
  switch (value) {
    case 'tenant':
      return UserRole.tenant;
    case 'landlord':
      return UserRole.landlord;
    case 'technician':
      return UserRole.technician;
    default:
      return UserRole.unknown;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.tenant:
      return 'tenant';
    case UserRole.landlord:
      return 'landlord';
    case UserRole.technician:
      return 'technician';
    case UserRole.unknown:
      return '';
  }
}

class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final DateTime? createdAt;
  final UserRole role;
  /// role이 landlord인 계정만 값이 있다. 회원가입 시 서버가 자동 발급하는 6자리
  /// 초대 코드 — 세입자가 이 코드를 입력해 자신과 연결한다(PATCH /api/users/link-landlord).
  final String? landlordCode;
  /// 이 사용자가 초대 코드로 연결한 임대인의 id. null이면 아직 연결되지 않은
  /// 상태다 — 이 경우 신고 접수(POST /api/reports)가 landlord_id 없이는 실패한다.
  final String? linkedLandlordId;
  /// role이 technician인 계정만 값이 있다. vendors.id — POST /api/quotes의
  /// vendor_id, GET /api/vendors/requests의 vendorId에 필요한 값이다. users.id와는
  /// 다른 값이므로 절대 혼용하면 안 된다(quotes.vendor_id는 vendors(id) FK).
  /// 백엔드가 signup/login 응답에 실어 주는 vendor.id를 그대로 저장한다 —
  /// AppUser.fromJson만으로는 못 채우고(응답의 형제 키라) 호출부에서 채워 넣는다.
  final String? vendorId;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.createdAt,
    required this.role,
    this.landlordCode,
    this.linkedLandlordId,
    this.vendorId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      // 백엔드 User 응답에는 email이 없다 (Supabase Auth 세션 쪽에만 있음).
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      role: userRoleFromString(json['role']?.toString()),
      landlordCode: json['landlord_code']?.toString(),
      linkedLandlordId: json['linked_landlord_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'role': userRoleToString(role),
      'landlord_code': landlordCode,
      'linked_landlord_id': linkedLandlordId,
      'vendor_id': vendorId,
    };
  }

  AppUser copyWith({UserRole? role, String? landlordCode, String? linkedLandlordId, String? vendorId}) {
    return AppUser(
      id: id,
      email: email,
      name: name,
      phone: phone,
      createdAt: createdAt,
      role: role ?? this.role,
      landlordCode: landlordCode ?? this.landlordCode,
      linkedLandlordId: linkedLandlordId ?? this.linkedLandlordId,
      vendorId: vendorId ?? this.vendorId,
    );
  }
}
