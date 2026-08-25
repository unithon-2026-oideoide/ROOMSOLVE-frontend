import '../models/user.dart';

/// role에 따라 진입할 홈 경로를 결정한다. router.dart의 리다이렉트 로직과
/// 동일한 규칙을 공유 화면(설정 등)에서도 쓰기 위한 헬퍼.
String homePathForRole(UserRole role) {
  switch (role) {
    case UserRole.landlord:
      return '/landlord';
    case UserRole.technician:
      return '/technician';
    case UserRole.tenant:
    case UserRole.unknown:
      return '/tenant';
  }
}

String requestsPathForRole(UserRole role) {
  switch (role) {
    case UserRole.landlord:
      return '/landlord/requests';
    case UserRole.technician:
      return '/technician/jobs';
    case UserRole.tenant:
    case UserRole.unknown:
      return '/tenant/reports';
  }
}

String roleLabel(UserRole role) {
  switch (role) {
    case UserRole.tenant:
      return '세입자';
    case UserRole.landlord:
      return '임대인';
    case UserRole.technician:
      return '수리기사';
    case UserRole.unknown:
      return '알 수 없음';
  }
}
