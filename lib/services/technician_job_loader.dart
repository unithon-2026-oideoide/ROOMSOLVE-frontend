import '../models/technician_job.dart';
import 'repair_service.dart';
import 'report_service.dart';

/// 진짜 배정 데이터가 없어([mockTechnicianJobs]로 대체됐는지) 화면이 구분할 수
/// 있게 [isMock] 플래그를 함께 준다.
typedef TechnicianJobsResult = ({List<TechnicianJob> jobs, bool isMock});

/// GET /api/repair/schedule?technicianId=로 배정된 일정을 가져오고, 각 일정의
/// report_id로 GET /api/reports/{id}를 호출해 상세를 조합한다.
///
/// technicianId가 없거나(로그인 안 됨) 배정이 정말 하나도 없으면(신규 계정 등)
/// isMock=true와 함께 [mockTechnicianJobs]로 대체해 화면이 비어 보이지 않게
/// 한다 — 이건 정상적인 빈 상태다.
///
/// 반대로 GET /api/repair/schedule 자체가 실패하면(네트워크/서버 오류)
/// 그 예외를 그대로 던진다. 예전에는 이 경우도 조용히 mock으로 대체했는데,
/// 그러면 서버가 500을 내도 기사가 (가짜 연락처가 포함된) 완전히 허구인
/// 목업 배정 목록을 실제 데이터로 착각할 수 있었다 — 에러와 "배정 없음"은
/// 화면에서 다르게 다뤄야 한다.
Future<TechnicianJobsResult> loadTechnicianJobs(String? technicianId) async {
  if (technicianId == null || technicianId.isEmpty) {
    return (jobs: mockTechnicianJobs, isMock: true);
  }

  final schedules = await RepairService.instance.getSchedules(technicianId: technicianId);
  if (schedules.isEmpty) return (jobs: mockTechnicianJobs, isMock: true);

  final jobs = await Future.wait(schedules.map((schedule) async {
    final reportId = schedule['report_id']?.toString();
    if (reportId == null) return null;
    try {
      final report = await ReportService.instance.getReport(reportId);
      return TechnicianJob.fromApi(
        schedule: schedule,
        report: {
          'id': report.id,
          'category': report.category,
          'description': report.description,
          'severity': report.severity,
          'status': report.status,
          'created_at': report.createdAt?.toIso8601String(),
        },
      );
    } catch (_) {
      // 이 건 하나의 상세 조회만 실패한 것 — 나머지 배정까지 통째로 버리지 않는다.
      return null;
    }
  }));

  final result = jobs.whereType<TechnicianJob>().toList();
  return result.isEmpty ? (jobs: mockTechnicianJobs, isMock: true) : (jobs: result, isMock: false);
}
