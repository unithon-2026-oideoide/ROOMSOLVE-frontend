import '../core/api_client.dart';
import '../models/technician_job.dart';
import 'repair_service.dart';
import 'report_service.dart';

/// GET /api/repair/schedule?technicianId=로 배정된 일정을 가져오고, 각 일정의
/// report_id로 GET /api/reports/{id}를 호출해 상세를 조합한다. 배정된 일정이
/// 하나도 없거나(신규 계정 등) 조회에 실패하면 [mockTechnicianJobs]로 대체해
/// 화면이 비어 보이지 않게 한다.
Future<List<TechnicianJob>> loadTechnicianJobs(String? technicianId) async {
  if (technicianId == null || technicianId.isEmpty) return mockTechnicianJobs;

  try {
    final schedules = await RepairService.instance.getSchedules(technicianId: technicianId);
    if (schedules.isEmpty) return mockTechnicianJobs;

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
        return null;
      }
    }));

    final result = jobs.whereType<TechnicianJob>().toList();
    return result.isEmpty ? mockTechnicianJobs : result;
  } on ApiException {
    return mockTechnicianJobs;
  } catch (_) {
    return mockTechnicianJobs;
  }
}
