class Quote {
  final String id;
  final String reportId;
  final String? vendorId;
  final String? vendorName;
  final num? price;
  final String status;
  final DateTime? createdAt;

  Quote({
    required this.id,
    required this.reportId,
    this.vendorId,
    this.vendorName,
    this.price,
    this.status = 'pending',
    this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id']?.toString() ?? '',
      reportId: json['reportId']?.toString() ?? '',
      vendorId: json['vendorId']?.toString(),
      vendorName: json['vendorName']?.toString(),
      price: json['price'] as num?,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
