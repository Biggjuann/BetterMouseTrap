class IdeaVariant {
  final String id;
  final String title;
  final String summary;
  final String improvementMode;
  final List<String> keywords;

  const IdeaVariant({
    required this.id,
    required this.title,
    required this.summary,
    required this.improvementMode,
    required this.keywords,
  });

  factory IdeaVariant.fromJson(Map<String, dynamic> json) => IdeaVariant(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        improvementMode: json['improvement_mode'] as String,
        keywords: List<String>.from(json['keywords'] as List),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'improvement_mode': improvementMode,
        'keywords': keywords,
      };

  String get modeLabel {
    switch (improvementMode) {
      case 'cost_down':
        return 'Cost Down';
      case 'durability':
        return 'Durability';
      case 'safety':
        return 'Safety';
      case 'convenience':
        return 'Convenience';
      case 'sustainability':
        return 'Sustainability';
      case 'performance':
        return 'Performance';
      case 'mashup':
        return 'Mashup';
      default:
        if (improvementMode.isEmpty) return 'Other';
        return improvementMode[0].toUpperCase() +
            improvementMode.substring(1).replaceAll('_', ' ');
    }
  }
}
