class IdeaScores {
  final int urgency;
  final int differentiation;
  final int speedToRevenue;
  final int margin;
  final int defensibility;
  final int distribution;

  const IdeaScores({
    this.urgency = 0,
    this.differentiation = 0,
    this.speedToRevenue = 0,
    this.margin = 0,
    this.defensibility = 0,
    this.distribution = 0,
  });

  factory IdeaScores.fromJson(Map<String, dynamic> json) => IdeaScores(
        urgency: (json['urgency'] as num?)?.toInt() ?? 0,
        differentiation: (json['differentiation'] as num?)?.toInt() ?? 0,
        speedToRevenue: (json['speed_to_revenue'] as num?)?.toInt() ?? 0,
        margin: (json['margin'] as num?)?.toInt() ?? 0,
        defensibility: (json['defensibility'] as num?)?.toInt() ?? 0,
        distribution: (json['distribution'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'urgency': urgency,
        'differentiation': differentiation,
        'speed_to_revenue': speedToRevenue,
        'margin': margin,
        'defensibility': defensibility,
        'distribution': distribution,
      };

  double get average =>
      (urgency + differentiation + speedToRevenue + margin + defensibility + distribution) / 6.0;
}

class IdeaVariant {
  final String id;
  final String title;
  final String summary;
  final String improvementMode;
  final List<String> keywords;

  // Sellable Ideas Engine fields
  final String tier; // top, moonshot, upgrade, adjacent, recurring
  final String? oneLinePitch;
  final String? targetCustomer;
  final String? coreProblem;
  final String? solution;
  final List<String> whyItWins;
  final String? monetization;
  final String? unitEconomics;
  final String? defensibilityNote;
  final String? mvp90Days;
  final List<String> goToMarket;
  final List<String> risks;
  final IdeaScores? scores;

  const IdeaVariant({
    required this.id,
    required this.title,
    required this.summary,
    this.improvementMode = 'mashup',
    this.keywords = const [],
    this.tier = 'upgrade',
    this.oneLinePitch,
    this.targetCustomer,
    this.coreProblem,
    this.solution,
    this.whyItWins = const [],
    this.monetization,
    this.unitEconomics,
    this.defensibilityNote,
    this.mvp90Days,
    this.goToMarket = const [],
    this.risks = const [],
    this.scores,
  });

  factory IdeaVariant.fromJson(Map<String, dynamic> json) => IdeaVariant(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        improvementMode:
            (json['improvement_mode'] as String?) ?? 'mashup',
        keywords: json['keywords'] != null
            ? List<String>.from(json['keywords'] as List)
            : [],
        tier: (json['tier'] as String?) ?? 'upgrade',
        oneLinePitch: json['one_line_pitch'] as String?,
        targetCustomer: json['target_customer'] as String?,
        coreProblem: json['core_problem'] as String?,
        solution: json['solution'] as String?,
        whyItWins: json['why_it_wins'] != null
            ? List<String>.from(json['why_it_wins'] as List)
            : [],
        monetization: json['monetization'] as String?,
        unitEconomics: json['unit_economics'] as String?,
        defensibilityNote: json['defensibility_note'] as String?,
        mvp90Days: json['mvp_90_days'] as String?,
        goToMarket: json['go_to_market'] != null
            ? List<String>.from(json['go_to_market'] as List)
            : [],
        risks: json['risks'] != null
            ? List<String>.from(json['risks'] as List)
            : [],
        scores: json['scores'] != null
            ? IdeaScores.fromJson(json['scores'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'improvement_mode': improvementMode,
        'keywords': keywords,
        'tier': tier,
        if (oneLinePitch != null) 'one_line_pitch': oneLinePitch,
        if (targetCustomer != null) 'target_customer': targetCustomer,
        if (coreProblem != null) 'core_problem': coreProblem,
        if (solution != null) 'solution': solution,
        if (whyItWins.isNotEmpty) 'why_it_wins': whyItWins,
        if (monetization != null) 'monetization': monetization,
        if (unitEconomics != null) 'unit_economics': unitEconomics,
        if (defensibilityNote != null) 'defensibility_note': defensibilityNote,
        if (mvp90Days != null) 'mvp_90_days': mvp90Days,
        if (goToMarket.isNotEmpty) 'go_to_market': goToMarket,
        if (risks.isNotEmpty) 'risks': risks,
        if (scores != null) 'scores': scores!.toJson(),
      };

  bool get isDetailed => tier == 'top' || tier == 'moonshot';

  String get tierLabel {
    switch (tier) {
      case 'top':
        return 'Top Pick';
      case 'moonshot':
        return 'Moonshot';
      case 'upgrade':
        return 'Upgrade';
      case 'adjacent':
        return 'Adjacent';
      case 'recurring':
        return 'Recurring';
      default:
        return tier[0].toUpperCase() + tier.substring(1);
    }
  }

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
