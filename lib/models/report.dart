/// AI가 분석한 하자보수 요청의 권장 처리 경로.
enum RecommendedPath { selfFix, manufacturerAs, vendorMatch, unknown }

RecommendedPath recommendedPathFromString(String? value) {
  switch (value) {
    case 'self_fix':
      return RecommendedPath.selfFix;
    case 'manufacturer_as':
      return RecommendedPath.manufacturerAs;
    case 'vendor_match':
      return RecommendedPath.vendorMatch;
    default:
      return RecommendedPath.unknown;
  }
}

class Report {
  final String id;
  final String? category;
  final String? severity;
  final String? description;
  /// 대표 사진 URL (백엔드 photo_url, NOT NULL).
  final String? photoUrl;
  /// 전체 사진 URL 목록 (백엔드 photo_urls).
  final List<String> photoUrls;
  final RecommendedPath recommendedPath;
  final String? selfFixGuide;
  final String? applianceType;
  final String? status;
  final DateTime? createdAt;

  Report({
    required this.id,
    this.category,
    this.severity,
    this.description,
    this.photoUrl,
    this.photoUrls = const [],
    this.recommendedPath = RecommendedPath.unknown,
    this.selfFixGuide,
    this.applianceType,
    this.status,
    this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString(),
      severity: json['severity']?.toString(),
      description: json['description']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      photoUrls: (json['photo_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      recommendedPath: recommendedPathFromString(json['recommended_path']?.toString()),
      selfFixGuide: json['self_fix_guide']?.toString(),
      applianceType: json['appliance_type']?.toString(),
      status: json['status']?.toString(),
      // 백엔드 컬럼명은 created_at(snake_case)이다. camelCase로 읽으면 항상 null이 되는
      // 버그가 있었다 — reports.controller.ts는 .select('*')로 DB 컬럼명을 그대로 준다.
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  /// landlord.controller.ts의 approveRequest가 세팅하는 값과 일치해야 한다.
  bool get isRejected => status == 'rejected';

  bool get isCompleted =>
      category == 'appliance' ||
      recommendedPath == RecommendedPath.manufacturerAs ||
      status == 'completed' ||
      status == 'done' ||
      status == '완료';

  bool get isWaiting =>
      !isCompleted &&
      !isRejected &&
      (status == null || status!.isEmpty || status == 'pending' || status == '대기');

  /// reports.status(pending/approved/rejected 등 백엔드 원문 문자열)를 화면에 보여줄
  /// 한국어 문구로 바꾼다. 가전(appliance) 하자는 추가 승인/수리 절차 없이 바로 제조사 AS로
  /// 연결되므로 '완료'로 표시한다.
  String get statusLabel {
    if (category == 'appliance' || recommendedPath == RecommendedPath.manufacturerAs) {
      return '완료';
    }
    switch (status) {
      case null:
      case '':
      case 'pending':
        return '접수 완료';
      case 'approved':
        return '수리 대기';
      case 'rejected':
        return '거절됨';
      case 'completed':
      case 'done':
        return '완료';
      default:
        return status!;
    }
  }
}
