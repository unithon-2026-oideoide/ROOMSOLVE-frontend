import '../core/category_helpers.dart';

/// GET /api/vendors/requests?vendorId= 의 각 항목. 업체가 아직 견적을 안 낸
/// (recommended_path가 vendor_match이고 selected된 견적이 없는) 신고를 담는다.
/// repair_schedule과는 무관하다 — 아직 일정이 없는 "새 일감 후보"다.
class VendorRequest {
  const VendorRequest({
    required this.id,
    required this.category,
    required this.severity,
    required this.description,
    required this.photoUrls,
    required this.availableTimes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String? category;
  final String? severity;
  final String? description;
  final List<String> photoUrls;
  /// 세입자가 집에 있는 시간대(자유 텍스트). db/009_quote_visit_and_reject.sql.
  final String? availableTimes;
  final String? status;
  final DateTime? createdAt;

  String get title => formatReportTitle(category, description);
  String? get photoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  factory VendorRequest.fromJson(Map<String, dynamic> json) {
    final rawPhotoUrls = json['photo_urls'];
    return VendorRequest(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString(),
      severity: json['severity']?.toString(),
      description: json['description']?.toString(),
      photoUrls: rawPhotoUrls is List ? rawPhotoUrls.map((e) => e.toString()).toList() : const [],
      availableTimes: json['available_times']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
