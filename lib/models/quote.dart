class Quote {
  final String id;
  final String reportId;
  final String? vendorId;
  final String? vendorName;
  final num? price;
  final String status;
  final DateTime? proposedVisitAt;
  final DateTime? createdAt;

  Quote({
    required this.id,
    required this.reportId,
    this.vendorId,
    this.vendorName,
    this.price,
    this.status = 'pending',
    this.proposedVisitAt,
    this.createdAt,
  });

  // 백엔드(quotes.controller.ts)는 report_id/vendor_id/created_at처럼 DB 컬럼명
  // 그대로(snake_case) 내려주고, 업체명은 vendorName이 아니라 중첩된
  // vendor:{id,name,rating,phone} 객체 안에 있다. 예전에는 camelCase 키
  // (reportId/vendorId/vendorName/createdAt)를 읽어서 전부 null/빈 문자열이 됐다.
  factory Quote.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return Quote(
      id: json['id']?.toString() ?? '',
      reportId: json['report_id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? vendor?['id']?.toString(),
      vendorName: vendor?['name']?.toString(),
      price: json['price'] as num?,
      status: json['status']?.toString() ?? 'pending',
      proposedVisitAt: json['proposed_visit_at'] != null ? DateTime.tryParse(json['proposed_visit_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
