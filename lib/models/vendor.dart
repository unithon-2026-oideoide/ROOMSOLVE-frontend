class Vendor {
  final String id;
  final String name;
  // 백엔드(POST /api/vendors/match, vendors.controller.ts)는 이 업체가 다루는
  // 여러 카테고리를 배열 필드 categories로 내려준다(단수 category 필드는 응답에
  // 없다) — 예전에는 category(단수)를 읽으려 해서 항상 null이었다.
  final List<String> categories;
  final double? rating;
  final String? phone;

  Vendor({
    required this.id,
    required this.name,
    this.categories = const [],
    this.rating,
    this.phone,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List?;
    return Vendor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categories: rawCategories?.map((e) => e.toString()).toList() ?? const [],
      rating: (json['rating'] as num?)?.toDouble(),
      phone: json['phone']?.toString(),
    );
  }
}
