import 'idea_variant.dart';
import 'idea_spec.dart';
import 'patent_hit.dart';

class GenerateIdeasResponse {
  final List<IdeaVariant> variants;

  const GenerateIdeasResponse({required this.variants});

  factory GenerateIdeasResponse.fromJson(Map<String, dynamic> json) =>
      GenerateIdeasResponse(
        variants: (json['variants'] as List)
            .map((v) => IdeaVariant.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class GenerateSpecResponse {
  final IdeaSpec spec;

  const GenerateSpecResponse({required this.spec});

  factory GenerateSpecResponse.fromJson(Map<String, dynamic> json) =>
      GenerateSpecResponse(
        spec: IdeaSpec.fromJson(json['spec'] as Map<String, dynamic>),
      );
}

class PatentSearchResponse {
  final List<PatentHit> hits;
  final String confidence;

  const PatentSearchResponse({required this.hits, required this.confidence});

  factory PatentSearchResponse.fromJson(Map<String, dynamic> json) =>
      PatentSearchResponse(
        hits: (json['hits'] as List)
            .map((h) => PatentHit.fromJson(h as Map<String, dynamic>))
            .toList(),
        confidence: json['confidence'] as String,
      );
}

class ExportResponse {
  final String markdown;
  final String plainText;

  const ExportResponse({required this.markdown, required this.plainText});

  factory ExportResponse.fromJson(Map<String, dynamic> json) =>
      ExportResponse(
        markdown: json['markdown'] as String,
        plainText: json['plain_text'] as String,
      );
}
