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
  final List<String> photoUrls;
  final RecommendedPath recommendedPath;
  final String? selfFixGuide;
  final String? status;
  final DateTime? createdAt;

  Report({
    required this.id,
    this.category,
    this.severity,
    this.description,
    this.photoUrls = const [],
    this.recommendedPath = RecommendedPath.unknown,
    this.selfFixGuide,
    this.status,
    this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString(),
      severity: json['severity']?.toString(),
      description: json['description']?.toString(),
      photoUrls: (json['photoUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      recommendedPath: recommendedPathFromString(json['recommended_path']?.toString()),
      selfFixGuide: json['self_fix_guide']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
