class Vendor {
  final String id;
  final String name;
  final String? category;
  final double? rating;
  final String? phone;

  Vendor({
    required this.id,
    required this.name,
    this.category,
    this.rating,
    this.phone,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      phone: json['phone']?.toString(),
    );
  }
}
