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
  final UserRole role;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      role: userRoleFromString(json['role']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': userRoleToString(role),
    };
  }

  AppUser copyWith({UserRole? role}) {
    return AppUser(
      id: id,
      email: email,
      name: name,
      role: role ?? this.role,
    );
  }
}
