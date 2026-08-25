import '../models/technician_job.dart';
import 'repair_service.dart';
import 'report_service.dart';

/// GET /api/repair/schedule?technicianId=로 배정된 일정을 가져오고, 각 일정의
/// report_id로 상세 정보(및 repair_status_timeline의 현재 상태)를 조합한다.
///
/// 배정된 일정이 없으면 빈 리스트를 반환한다 — 예전에는 이 경우
/// mockTechnicianJobs로 대체해서, 신규 계정이든 조회 실패든 항상 그럴싸한
/// 가짜 배정 목록(가짜 연락처 포함)이 보이는 문제가 있었다. 지금은 진짜
/// 데이터가 없으면 화면이 빈 상태를 있는 그대로 보여준다(각 화면의 "배정된
/// 방문 일정이 없습니다" 등 안내 참고).
///
/// technicianId가 없으면(로그인 안 됨) 빈 리스트를 반환한다. 반면
/// GET /api/repair/schedule 자체가 실패하면(네트워크/서버 오류) 그 예외를
/// 그대로 던진다 — "배정 없음"과 "조회 실패"를 화면에서 다르게 보여줘야
/// 하기 때문이다(뭉뚱그려 빈 리스트로 처리하면 오류가 조용히 사라진다).
Future<List<TechnicianJob>> loadTechnicianJobs(String? technicianId) async {
  if (technicianId == null || technicianId.isEmpty) return [];

  final schedules = await RepairService.instance.getSchedules(technicianId: technicianId);
  if (schedules.isEmpty) return [];

  final jobs = await Future.wait(schedules.map((schedule) async {
    final reportId = schedule['report_id']?.toString();
    if (reportId == null) return null;

    String? currentRepairStatus;
    try {
      final timelineData = await RepairService.instance.getTimeline(reportId);
      currentRepairStatus = timelineData.currentStatus;
    } catch (_) {
      // 타임라인 조회 실패는 무시한다 — 상태 표시가 조금 덜 정확해질 뿐,
      // 작업 자체는 여전히 보여줘야 한다.
    }

    Map<String, dynamic> reportMap = {};
    try {
      final report = await ReportService.instance.getReport(reportId);
      reportMap = {
        'id': report.id,
        'category': report.category,
        'description': report.description,
        'severity': report.severity,
        'status': report.status,
        'photo_url': report.photoUrl,
        'photo_urls': report.photoUrls,
        'created_at': report.createdAt?.toIso8601String(),
      };
    } catch (_) {
      // 리포트 상세 조회가 실패해도 일정(schedule)에 딸려온 정보가 있으면 그걸 쓴다.
      if (schedule['report'] is Map) {
        reportMap = Map<String, dynamic>.from(schedule['report'] as Map);
      }
    }

    return TechnicianJob.fromApi(
      schedule: schedule,
      report: reportMap.isNotEmpty
          ? reportMap
          : {
              'id': reportId,
              'category': schedule['category'],
              'description': schedule['description'],
              'severity': schedule['severity'],
              'status': schedule['status'],
              'photo_url': schedule['photo_url'],
              'photo_urls': schedule['photo_urls'],
              'created_at': schedule['created_at'] ?? schedule['scheduled_at'],
            },
      currentRepairStatus: currentRepairStatus,
    );
  }));

  return jobs.whereType<TechnicianJob>().toList();
}
