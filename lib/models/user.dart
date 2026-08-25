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

  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.createdAt,
    required this.role,
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
    };
  }

  AppUser copyWith({UserRole? role}) {
    return AppUser(
      id: id,
      email: email,
      name: name,
      phone: phone,
      createdAt: createdAt,
      role: role ?? this.role,
    );
  }
}
