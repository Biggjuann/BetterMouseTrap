class ProvisionalPatentResponse {
  final String title;
  final String abstract_;
  final Map<String, dynamic> claims;
  final String detailedDescription;
  final String priorArtDiscussion;
  final String markdown;

  const ProvisionalPatentResponse({
    required this.title,
    required this.abstract_,
    required this.claims,
    required this.detailedDescription,
    required this.priorArtDiscussion,
    required this.markdown,
  });

  factory ProvisionalPatentResponse.fromJson(Map<String, dynamic> json) =>
      ProvisionalPatentResponse(
        title: json['title'] as String,
        abstract_: json['abstract'] as String,
        claims: json['claims'] as Map<String, dynamic>,
        detailedDescription: json['detailed_description'] as String,
        priorArtDiscussion: json['prior_art_discussion'] as String,
        markdown: json['markdown'] as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'abstract': abstract_,
        'claims': claims,
        'detailed_description': detailedDescription,
        'prior_art_discussion': priorArtDiscussion,
        'markdown': markdown,
      };
}
