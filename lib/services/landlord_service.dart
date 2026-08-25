import '../core/api_client.dart';

class LandlordService {
  LandlordService._();
  static final LandlordService instance = LandlordService._();

  final _api = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getRequests() async {
    final response = await _api.get('/api/landlord/requests');
    final data = response.data as Map<String, dynamic>;
    final list = (data['requests'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getRequestDetail(String id) async {
    final response = await _api.get('/api/landlord/requests/$id');
    final data = response.data as Map<String, dynamic>;
    return data['request'] as Map<String, dynamic>;
  }

  /// PATCH /api/landlord/requests/{id}/approve — 바디 키는 approve가 아니라 approved다
  /// (landlord.controller.ts의 approveRequest 확인함).
  Future<void> approveRequest({required String id, required bool approve}) async {
    await _api.patch('/api/landlord/requests/$id/approve', data: {'approved': approve});
  }

  /// GET /api/landlord/auto-approval-policy — 카테고리별로 저장된 자동승인
  /// 한도 목록. 각 항목은 {category, auto_approve_limit} 형태.
  Future<List<Map<String, dynamic>>> getAutoApprovalPolicies() async {
    final response = await _api.get('/api/landlord/auto-approval-policy');
    final data = response.data as Map<String, dynamic>;
    final list = (data['policies'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /api/landlord/auto-approval-policy — 카테고리 하나의 한도를 저장(upsert)한다.
  /// 백엔드가 category(단일)/auto_approve_limit만 받는다(landlord.controller.ts
  /// createAutoApprovalPolicy 확인함) — 여러 카테고리를 한 번에 저장하려면
  /// 카테고리 수만큼 이 메서드를 반복 호출해야 한다.
  Future<void> setAutoApprovalPolicy({required String category, required int autoApproveLimit}) async {
    await _api.post('/api/landlord/auto-approval-policy', data: {
      'category': category,
      'auto_approve_limit': autoApproveLimit,
    });
  }

  /// GET /api/landlord/properties — "호실" 테이블이 없어서 실제로는 이 임대인에게
  /// 신고를 보낸 세입자 목록({id, name, phone})을 중복 제거해 반환한다
  /// (landlord.controller.ts의 listProperties 확인함). unit/status/contractEnd
  /// 같은 필드는 없다 — 화면 쪽 매핑은 아직 안 고쳤다(알려진 4번 항목).
  Future<List<Map<String, dynamic>>> getProperties() async {
    final response = await _api.get('/api/landlord/properties');
    final data = response.data as Map<String, dynamic>;
    final list = (data['properties'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
