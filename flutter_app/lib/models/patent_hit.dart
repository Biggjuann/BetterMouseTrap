class PatentHit {
  final String patentId;
  final String title;
  final String abstract_;
  final String? assignee;
  final String? date;
  final double score;
  final String whySimilar;

  const PatentHit({
    required this.patentId,
    required this.title,
    required this.abstract_,
    this.assignee,
    this.date,
    required this.score,
    required this.whySimilar,
  });

  factory PatentHit.fromJson(Map<String, dynamic> json) => PatentHit(
        patentId: json['patent_id'] as String,
        title: json['title'] as String,
        abstract_: json['abstract'] as String,
        assignee: json['assignee'] as String?,
        date: json['date'] as String?,
        score: (json['score'] as num).toDouble(),
        whySimilar: json['why_similar'] as String,
      );

  Map<String, dynamic> toJson() => {
        'patent_id': patentId,
        'title': title,
        'abstract': abstract_,
        if (assignee != null) 'assignee': assignee,
        if (date != null) 'date': date,
        'score': score,
        'why_similar': whySimilar,
      };

  int get scorePercent => (score * 100).round();
}
