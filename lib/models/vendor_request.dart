import '../core/category_helpers.dart';

/// GET /api/vendors/requests?technicianId= 의 각 항목. 업체의 전문 분야에
/// 해당하고 아직 낙찰(selected)된 견적이 없는 신고를 담는다. repair_schedule과는
/// 무관하다 — 아직 일정이 없는 "새 일감 후보"다.
class VendorRequest {
  const VendorRequest({
    required this.id,
    required this.category,
    required this.severity,
    required this.description,
    required this.photoUrl,
    required this.photoUrls,
    required this.availableTimes,
    required this.status,
    required this.createdAt,
    required this.alreadyQuoted,
  });

  final String id;
  final String? category;
  final String? severity;
  final String? description;
  final String? photoUrl;
  final List<String> photoUrls;
  /// 세입자가 집에 있는 시간대(자유 텍스트). db/009_quote_visit_and_reject.sql.
  final String? availableTimes;
  final String? status;
  final DateTime? createdAt;
  /// 이 업체가 이미 이 신고에 견적을 낸 상태인지. true면 상세 화면에서 견적
  /// 폼 대신 "이미 제출한 견적"임을 보여주고 재제출을 막아야 한다 — 막지
  /// 않으면 quotes에 중복 행이 쌓인다(막는 제약이 DB에 없다).
  final bool alreadyQuoted;

  String get title => formatReportTitle(category, description);

  factory VendorRequest.fromJson(Map<String, dynamic> json) {
    final rawPhotoUrls = json['photo_urls'];
    final photoUrls = rawPhotoUrls is List ? rawPhotoUrls.map((e) => e.toString()).toList() : const <String>[];
    return VendorRequest(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString(),
      severity: json['severity']?.toString(),
      description: json['description']?.toString(),
      // 대표 사진 photo_url이 없으면(예전 데이터) photo_urls의 첫 장으로 대신한다.
      photoUrl: json['photo_url']?.toString() ?? (photoUrls.isNotEmpty ? photoUrls.first : null),
      photoUrls: photoUrls,
      availableTimes: json['available_times']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      alreadyQuoted: json['alreadyQuoted'] == true,
    );
  }
}
