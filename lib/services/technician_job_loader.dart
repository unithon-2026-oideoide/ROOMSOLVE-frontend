import '../models/technician_job.dart';
import 'repair_service.dart';
import 'report_service.dart';

/// GET /api/repair/schedule?technicianId=로 배정된 일정을 가져오고, 각 일정의
/// report_id로 상세 정보를 조합한다. 배정된 일정이 없으면 빈 리스트를 반환한다.
Future<List<TechnicianJob>> loadTechnicianJobs(String? technicianId) async {
  if (technicianId == null || technicianId.isEmpty) return [];

  try {
    final schedules = await RepairService.instance.getSchedules(technicianId: technicianId);
    if (schedules.isEmpty) return [];

    final jobs = await Future.wait(schedules.map((schedule) async {
      final reportId = schedule['report_id']?.toString();
      if (reportId == null) return null;

      String? currentRepairStatus;
      try {
        final timelineData = await RepairService.instance.getTimeline(reportId);
        currentRepairStatus = timelineData.currentStatus;
      } catch (_) {}

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
  } catch (_) {
    return [];
  }
}
