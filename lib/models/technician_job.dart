/// GET /api/repair/schedule(technicianId=)와 GET /api/reports/{id}를 조합해
/// 화면에 필요한 형태로 만든다.
import '../core/category_helpers.dart';

enum TechnicianJobStatus { scheduled, inProgress, onHold, completed }

class TechnicianJob {
  const TechnicianJob({
    required this.id,
    required this.title,
    required this.unit,
    required this.tenantName,
    required this.address,
    required this.visitTime,
    required this.priority,
    required this.status,
    required this.symptomDescription,
    required this.instruction,
    required this.contactPhone,
    required this.receivedAt,
    this.estimatedCost,
    this.actualCost,
    this.scheduleId,
    this.photoUrl,
    this.photoUrls = const [],
  });

  final String id;
  final String title;
  final String unit;
  final String tenantName;
  final String address;
  final String visitTime;
  final String priority;
  final TechnicianJobStatus status;
  final String symptomDescription;
  final String instruction;
  final String contactPhone;
  final String receivedAt;
  final String? estimatedCost;
  final String? actualCost;
  /// 실제 RepairSchedule 항목의 id (PATCH .../confirm에 필요).
  final String? scheduleId;
  final String? photoUrl;
  final List<String> photoUrls;

  String get statusLabel {
    switch (status) {
      case TechnicianJobStatus.scheduled:
        return '방문 예정';
      case TechnicianJobStatus.inProgress:
        return '진행 중';
      case TechnicianJobStatus.onHold:
        return '보류';
      case TechnicianJobStatus.completed:
        return '완료';
    }
  }

  static String _severityToPriority(String? severity) {
    switch (severity) {
      case 'emergency':
        return '긴급';
      case 'high':
        return '높음';
      case 'medium':
        return '보통';
      case 'low':
        return '낮음';
      default:
        return '일반';
    }
  }

  static TechnicianJobStatus _resolveStatus({
    required bool confirmed,
    required String? reportStatus,
    String? currentRepairStatus,
  }) {
    final timeline = currentRepairStatus?.toLowerCase();
    if (timeline == 'done' || timeline == 'completed' || timeline == '완료') {
      return TechnicianJobStatus.completed;
    }
    if (timeline == 'in_progress' || timeline == '진행' || timeline == '진행 중') {
      return TechnicianJobStatus.inProgress;
    }
    if (timeline == 'confirmed') {
      return TechnicianJobStatus.inProgress;
    }
    if (timeline == 'scheduled') {
      return TechnicianJobStatus.scheduled;
    }

    final report = reportStatus?.toLowerCase();
    if (report == 'done' || report == 'completed' || report == '완료') {
      return TechnicianJobStatus.completed;
    }
    if (report == 'in_progress') {
      return TechnicianJobStatus.inProgress;
    }
    return confirmed ? TechnicianJobStatus.inProgress : TechnicianJobStatus.scheduled;
  }

  static String _formatVisitTime(String? isoString) {
    if (isoString == null) return '일정 미정';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '일정 미정';
    final period = dt.hour < 12 ? '오전' : '오후';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '$period $hour12:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _formatReceivedAt(String? isoString) {
    if (isoString == null) return '날짜 미상';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '날짜 미상';
    return '${dt.year}년 ${dt.month}월 ${dt.day}일';
  }

  factory TechnicianJob.fromApi({
    required Map<String, dynamic> schedule,
    required Map<String, dynamic> report,
    String? currentRepairStatus,
  }) {
    final confirmed = schedule['confirmed'] == true;
    final photoUrl = report['photo_url']?.toString() ?? schedule['photo_url']?.toString();
    final rawPhotoUrls = report['photo_urls'] ?? schedule['photo_urls'];
    final photoUrls = (rawPhotoUrls is List)
        ? rawPhotoUrls.map((e) => e.toString()).toList()
        : (photoUrl != null ? [photoUrl] : <String>[]);

    final tenant = (report['tenant'] is Map) ? (report['tenant'] as Map) : null;
    final tenantName = tenant?['name']?.toString() ?? report['tenant_name']?.toString() ?? '';
    final tenantPhone = tenant?['phone']?.toString() ?? report['tenant_phone']?.toString() ?? '';
    final unit = report['unit']?.toString() ?? '';
    final address = report['address']?.toString() ?? '';

    return TechnicianJob(
      id: report['id']?.toString() ?? schedule['report_id']?.toString() ?? '',
      title: formatReportTitle(report['category']?.toString(), report['description']?.toString()),
      unit: unit,
      tenantName: tenantName,
      address: address,
      visitTime: _formatVisitTime(schedule['scheduled_at']?.toString()),
      priority: _severityToPriority(report['severity']?.toString()),
      status: _resolveStatus(
        confirmed: confirmed,
        reportStatus: report['status']?.toString(),
        currentRepairStatus: currentRepairStatus,
      ),
      symptomDescription: report['description']?.toString() ?? '증상 설명이 없습니다.',
      instruction: report['self_fix_guide']?.toString() ?? '작업 지시 정보가 아직 제공되지 않습니다.',
      contactPhone: tenantPhone.isNotEmpty ? tenantPhone : '연락처 정보 없음',
      receivedAt: _formatReceivedAt(report['created_at']?.toString() ?? schedule['created_at']?.toString()),
      scheduleId: schedule['id']?.toString(),
      photoUrl: photoUrl,
      photoUrls: photoUrls,
    );
  }
}
