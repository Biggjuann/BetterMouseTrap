// Models for the professional patent analysis response.

class CpcSuggestion {
  final String code;
  final String description;
  final String rationale;

  const CpcSuggestion({
    required this.code,
    required this.description,
    required this.rationale,
  });

  factory CpcSuggestion.fromJson(Map<String, dynamic> json) => CpcSuggestion(
        code: json['code'] as String,
        description: json['description'] as String,
        rationale: json['rationale'] as String,
      );
}

class SearchStrategy {
  final String query;
  final String approach;
  final String targetField;

  const SearchStrategy({
    required this.query,
    required this.approach,
    required this.targetField,
  });

  factory SearchStrategy.fromJson(Map<String, dynamic> json) => SearchStrategy(
        query: json['query'] as String,
        approach: json['approach'] as String,
        targetField: json['target_field'] as String,
      );
}

class InventionAnalysis {
  final String coreConcept;
  final List<String> essentialElements;
  final List<String> alternativeImplementations;
  final List<CpcSuggestion> cpcCodes;
  final List<SearchStrategy> searchStrategies;

  const InventionAnalysis({
    required this.coreConcept,
    required this.essentialElements,
    required this.alternativeImplementations,
    required this.cpcCodes,
    required this.searchStrategies,
  });

  factory InventionAnalysis.fromJson(Map<String, dynamic> json) =>
      InventionAnalysis(
        coreConcept: json['core_concept'] as String,
        essentialElements:
            List<String>.from(json['essential_elements'] as List),
        alternativeImplementations:
            List<String>.from(json['alternative_implementations'] as List),
        cpcCodes: (json['cpc_codes'] as List)
            .map((c) => CpcSuggestion.fromJson(c as Map<String, dynamic>))
            .toList(),
        searchStrategies: (json['search_strategies'] as List)
            .map((s) => SearchStrategy.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class EnhancedPatentHit {
  final String patentId;
  final String title;
  final String abstract_;
  final String? assignee;
  final String? date;
  final List<String> cpcCodes;
  final double score;
  final String whySimilar;
  final String sourcePhase;

  const EnhancedPatentHit({
    required this.patentId,
    required this.title,
    required this.abstract_,
    this.assignee,
    this.date,
    required this.cpcCodes,
    required this.score,
    required this.whySimilar,
    required this.sourcePhase,
  });

  factory EnhancedPatentHit.fromJson(Map<String, dynamic> json) =>
      EnhancedPatentHit(
        patentId: json['patent_id'] as String,
        title: json['title'] as String,
        abstract_: json['abstract'] as String,
        assignee: json['assignee'] as String?,
        date: json['date'] as String?,
        cpcCodes: List<String>.from(json['cpc_codes'] as List? ?? []),
        score: (json['score'] as num).toDouble(),
        whySimilar: json['why_similar'] as String,
        sourcePhase: json['source_phase'] as String,
      );

  Map<String, dynamic> toJson() => {
        'patent_id': patentId,
        'title': title,
        'abstract': abstract_,
        if (assignee != null) 'assignee': assignee,
        if (date != null) 'date': date,
        'cpc_codes': cpcCodes,
        'score': score,
        'why_similar': whySimilar,
        'source_phase': sourcePhase,
      };

  int get scorePercent => (score * 100).round();

  String get sourcePhasLabel {
    switch (sourcePhase) {
      case 'keyword':
        return 'Keyword';
      case 'cpc':
        return 'CPC Class';
      case 'citation':
        return 'Citation';
      default:
        return sourcePhase;
    }
  }
}

class SearchMetadata {
  final int totalQueriesRun;
  final int keywordHits;
  final int cpcHits;
  final int citationHits;
  final int duplicatesRemoved;
  final List<String> phasesCompleted;

  const SearchMetadata({
    required this.totalQueriesRun,
    required this.keywordHits,
    required this.cpcHits,
    required this.citationHits,
    required this.duplicatesRemoved,
    required this.phasesCompleted,
  });

  factory SearchMetadata.fromJson(Map<String, dynamic> json) => SearchMetadata(
        totalQueriesRun: json['total_queries_run'] as int,
        keywordHits: json['keyword_hits'] as int,
        cpcHits: json['cpc_hits'] as int,
        citationHits: json['citation_hits'] as int,
        duplicatesRemoved: json['duplicates_removed'] as int,
        phasesCompleted: List<String>.from(json['phases_completed'] as List),
      );
}

class NoveltyAssessment {
  final String riskLevel;
  final String summary;
  final String? closestReference;
  final List<String> missingElements;

  const NoveltyAssessment({
    required this.riskLevel,
    required this.summary,
    this.closestReference,
    required this.missingElements,
  });

  factory NoveltyAssessment.fromJson(Map<String, dynamic> json) =>
      NoveltyAssessment(
        riskLevel: json['risk_level'] as String,
        summary: json['summary'] as String,
        closestReference: json['closest_reference'] as String?,
        missingElements:
            List<String>.from(json['missing_elements'] as List? ?? []),
      );
}

class ObviousnessAssessment {
  final String riskLevel;
  final String summary;
  final List<String> combinationRefs;

  const ObviousnessAssessment({
    required this.riskLevel,
    required this.summary,
    required this.combinationRefs,
  });

  factory ObviousnessAssessment.fromJson(Map<String, dynamic> json) =>
      ObviousnessAssessment(
        riskLevel: json['risk_level'] as String,
        summary: json['summary'] as String,
        combinationRefs:
            List<String>.from(json['combination_refs'] as List? ?? []),
      );
}

class EligibilityNote {
  final bool applies;
  final String summary;

  const EligibilityNote({required this.applies, required this.summary});

  factory EligibilityNote.fromJson(Map<String, dynamic> json) =>
      EligibilityNote(
        applies: json['applies'] as bool,
        summary: json['summary'] as String,
      );
}

class PriorArtSummary {
  final String overallRisk;
  final String narrative;
  final List<String> keyFindings;

  const PriorArtSummary({
    required this.overallRisk,
    required this.narrative,
    required this.keyFindings,
  });

  factory PriorArtSummary.fromJson(Map<String, dynamic> json) =>
      PriorArtSummary(
        overallRisk: json['overall_risk'] as String,
        narrative: json['narrative'] as String,
        keyFindings: List<String>.from(json['key_findings'] as List),
      );
}

class ClaimStrategy {
  final String recommendedFiling;
  final String rationale;
  final List<String> suggestedIndependentClaims;
  final List<String> riskAreas;

  const ClaimStrategy({
    required this.recommendedFiling,
    required this.rationale,
    required this.suggestedIndependentClaims,
    required this.riskAreas,
  });

  factory ClaimStrategy.fromJson(Map<String, dynamic> json) => ClaimStrategy(
        recommendedFiling: json['recommended_filing'] as String,
        rationale: json['rationale'] as String,
        suggestedIndependentClaims: List<String>.from(
            json['suggested_independent_claims'] as List? ?? []),
        riskAreas: List<String>.from(json['risk_areas'] as List? ?? []),
      );

  String get filingLabel {
    switch (recommendedFiling) {
      case 'provisional':
        return 'Provisional Patent';
      case 'non_provisional':
        return 'Full Patent Application';
      case 'design_patent':
        return 'Design Patent';
      case 'defer':
        return 'Defer Filing';
      case 'abandon':
        return 'Not Recommended';
      default:
        return recommendedFiling;
    }
  }
}

class PatentAnalysisResponse {
  final InventionAnalysis inventionAnalysis;
  final List<EnhancedPatentHit> hits;
  final SearchMetadata searchMetadata;
  final NoveltyAssessment noveltyAssessment;
  final ObviousnessAssessment obviousnessAssessment;
  final EligibilityNote eligibilityNote;
  final PriorArtSummary priorArtSummary;
  final ClaimStrategy claimStrategy;
  final String confidence;
  final String disclaimer;

  const PatentAnalysisResponse({
    required this.inventionAnalysis,
    required this.hits,
    required this.searchMetadata,
    required this.noveltyAssessment,
    required this.obviousnessAssessment,
    required this.eligibilityNote,
    required this.priorArtSummary,
    required this.claimStrategy,
    required this.confidence,
    required this.disclaimer,
  });

  factory PatentAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      PatentAnalysisResponse(
        inventionAnalysis: InventionAnalysis.fromJson(
            json['invention_analysis'] as Map<String, dynamic>),
        hits: (json['hits'] as List)
            .map((h) =>
                EnhancedPatentHit.fromJson(h as Map<String, dynamic>))
            .toList(),
        searchMetadata: SearchMetadata.fromJson(
            json['search_metadata'] as Map<String, dynamic>),
        noveltyAssessment: NoveltyAssessment.fromJson(
            json['novelty_assessment'] as Map<String, dynamic>),
        obviousnessAssessment: ObviousnessAssessment.fromJson(
            json['obviousness_assessment'] as Map<String, dynamic>),
        eligibilityNote: EligibilityNote.fromJson(
            json['eligibility_note'] as Map<String, dynamic>),
        priorArtSummary: PriorArtSummary.fromJson(
            json['prior_art_summary'] as Map<String, dynamic>),
        claimStrategy: ClaimStrategy.fromJson(
            json['claim_strategy'] as Map<String, dynamic>),
        confidence: json['confidence'] as String,
        disclaimer: json['disclaimer'] as String,
      );
}
