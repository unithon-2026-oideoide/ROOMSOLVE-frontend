import '../core/api_client.dart';

/// 방문 일정(schedule)과 진행 상태 이력(timeline) API, 자가수리 챗봇 API.
/// 스웨거 문서(http://134.185.108.221:3000/api-docs/#/) 기준.
class RepairService {
  RepairService._();
  static final RepairService instance = RepairService._();

  final _api = ApiClient.instance;

  /// GET /api/repair/schedule — reportId 또는 technicianId 중 최소 하나 필요.
  /// 각 항목에 담당 technician(id/name/phone)이 조인되어 함께 온다.
  Future<List<Map<String, dynamic>>> getSchedules({String? reportId, String? technicianId}) async {
    final response = await _api.get('/api/repair/schedule', queryParameters: {
      'reportId': ?reportId,
      'technicianId': ?technicianId,
    });
    final data = response.data as Map<String, dynamic>;
    final list = (data['schedules'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /api/repair/schedule — 방문 일정 등록. 인증이 없어 technician_id를
  /// body로 직접 받으며, 실제 존재하는 사용자여야 한다(users FK).
  Future<Map<String, dynamic>> createSchedule({
    required String reportId,
    required String technicianId,
    required DateTime scheduledAt,
  }) async {
    final response = await _api.post('/api/repair/schedule', data: {
      'report_id': reportId,
      'technician_id': technicianId,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    });
    final data = response.data as Map<String, dynamic>;
    return data['schedule'] as Map<String, dynamic>;
  }

  /// PATCH /api/repair/schedule/{id}/confirm — 방문 일정 확정.
  Future<Map<String, dynamic>> confirmSchedule(String scheduleId) async {
    final response = await _api.patch('/api/repair/schedule/$scheduleId/confirm');
    final data = response.data as Map<String, dynamic>;
    return data['schedule'] as Map<String, dynamic>;
  }

  /// POST /api/repair/status — 진행 상태 이력 한 줄 추가.
  /// status는 자유 문자열이며 scheduled/confirmed/in_progress/done 정도를 상정.
  Future<Map<String, dynamic>> postStatus({required String reportId, required String status}) async {
    final response = await _api.post('/api/repair/status', data: {
      'report_id': reportId,
      'status': status,
    });
    final data = response.data as Map<String, dynamic>;
    return data['entry'] as Map<String, dynamic>;
  }

  /// GET /api/repair/timeline — 상태 이력 + 현재 상태.
  Future<({List<Map<String, dynamic>> timeline, String? currentStatus})> getTimeline(String reportId) async {
    final response = await _api.get('/api/repair/timeline', queryParameters: {'reportId': reportId});
    final data = response.data as Map<String, dynamic>;
    final list = (data['timeline'] as List?) ?? [];
    return (
      timeline: list.cast<Map<String, dynamic>>(),
      currentStatus: data['currentStatus']?.toString(),
    );
  }

  /// POST /api/reports/chat — 자가수리 AI 챗봇 상담.
  /// context는 POST /api/reports/analyze 응답(category/severity/recommended_path/
  /// self_fix_guide)을 그대로 넣으면 된다. messages는 지금까지의 대화(첫 턴은 빈 배열).
  Future<({String reply, bool escalate, String? escalateTo})> chat({
    required Map<String, dynamic> context,
    required List<Map<String, String>> messages,
  }) async {
    final response = await _api.post('/api/reports/chat', data: {
      'context': context,
      'messages': messages,
    });
    final data = response.data as Map<String, dynamic>;
    return (
      reply: data['reply']?.toString() ?? '',
      escalate: data['escalate'] == true,
      escalateTo: data['escalate_to']?.toString(),
    );
  }
}
