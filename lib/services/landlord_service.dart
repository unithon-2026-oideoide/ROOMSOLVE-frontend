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

  Future<void> setAutoApprovalPolicy({required Map<String, dynamic> policy}) async {
    await _api.post('/api/landlord/auto-approval-policy', data: policy);
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
