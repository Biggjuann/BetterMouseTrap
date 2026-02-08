class IdeaSpec {
  final String novelty;
  final String mechanism;
  final String baseline;
  final List<String> differentiators;
  final List<String> keywords;
  final List<String> searchQueries;
  final String disclaimer;

  const IdeaSpec({
    required this.novelty,
    required this.mechanism,
    required this.baseline,
    required this.differentiators,
    required this.keywords,
    required this.searchQueries,
    required this.disclaimer,
  });

  factory IdeaSpec.fromJson(Map<String, dynamic> json) => IdeaSpec(
        novelty: json['novelty'] as String,
        mechanism: json['mechanism'] as String,
        baseline: json['baseline'] as String,
        differentiators: List<String>.from(json['differentiators'] as List),
        keywords: List<String>.from(json['keywords'] as List),
        searchQueries: List<String>.from(json['search_queries'] as List),
        disclaimer: json['disclaimer'] as String,
      );

  Map<String, dynamic> toJson() => {
        'novelty': novelty,
        'mechanism': mechanism,
        'baseline': baseline,
        'differentiators': differentiators,
        'keywords': keywords,
        'search_queries': searchQueries,
        'disclaimer': disclaimer,
      };
}
