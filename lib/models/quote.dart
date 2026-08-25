class Quote {
  final String id;
  final String reportId;
  final String? vendorId;
  final String? vendorName;
  final double? vendorRating;
  final num? price;
  final String status;
  final DateTime? proposedVisitAt;
  final DateTime? createdAt;

  /// 가격과 평점을 합친 점수의 순위. 서버가 조회할 때마다 다시 계산하며,
  /// 거절된 견적은 순위에서 빠지므로 null이다.
  final int? rank;

  /// 1위 견적. 목록에서 추천 배지를 다는 기준.
  final bool isRecommended;

  /// 왜 이게 1위인지 한 줄 설명. 추천이 아닌 견적은 null.
  final String? recommendReason;

  /// 중앙값의 2배를 넘는 과도한 견적.
  final bool isOutlier;
  final String? outlierReason;

  Quote({
    required this.id,
    required this.reportId,
    this.vendorId,
    this.vendorName,
    this.vendorRating,
    this.price,
    this.status = 'pending',
    this.proposedVisitAt,
    this.createdAt,
    this.rank,
    this.isRecommended = false,
    this.recommendReason,
    this.isOutlier = false,
    this.outlierReason,
  });

  // 백엔드(quotes.controller.ts)는 report_id/vendor_id/created_at처럼 DB 컬럼명
  // 그대로(snake_case) 내려주고, 업체명은 vendorName이 아니라 중첩된
  // vendor:{id,name,rating,phone} 객체 안에 있다. 예전에는 camelCase 키
  // (reportId/vendorId/vendorName/createdAt)를 읽어서 전부 null/빈 문자열이 됐다.
  //
  // 순위 관련 네 필드(rank/isRecommended/recommendReason/isOutlier)는 DB 컬럼이
  // 아니라 조회 시점에 계산돼 붙는 값이라 camelCase 그대로 온다.
  factory Quote.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return Quote(
      id: json['id']?.toString() ?? '',
      reportId: json['report_id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? vendor?['id']?.toString(),
      vendorName: vendor?['name']?.toString(),
      vendorRating: (vendor?['rating'] as num?)?.toDouble(),
      price: json['price'] as num?,
      status: json['status']?.toString() ?? 'pending',
      proposedVisitAt: json['proposed_visit_at'] != null ? DateTime.tryParse(json['proposed_visit_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      rank: json['rank'] as int?,
      isRecommended: json['isRecommended'] == true,
      recommendReason: json['recommendReason']?.toString(),
      isOutlier: json['isOutlier'] == true,
      outlierReason: json['outlierReason']?.toString(),
    );
  }
}
