class SessionSummary {
  final String id;
  final String? title;
  final String productText;
  final String status;
  final String createdAt;
  final String updatedAt;

  const SessionSummary({
    required this.id,
    this.title,
    required this.productText,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
        id: json['id'] as String,
        title: json['title'] as String?,
        productText: json['product_text'] as String,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  String get displayTitle => title ?? productText;

  String get statusLabel {
    switch (status) {
      case 'started':
        return 'Started';
      case 'ideas_generated':
        return 'Ideas Generated';
      case 'spec_generated':
        return 'Spec Ready';
      case 'patents_searched':
        return 'Patents Searched';
      case 'exported':
        return 'Exported';
      default:
        return status;
    }
  }
}
