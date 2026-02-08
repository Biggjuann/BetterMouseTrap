import 'idea_variant.dart';
import 'idea_spec.dart';
import 'patent_hit.dart';
import 'product_input.dart';

class GenerateIdeasRequest {
  final String text;
  final String? category;
  final bool random;

  const GenerateIdeasRequest({
    required this.text,
    this.category,
    this.random = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        if (category != null) 'category': category,
        'random': random,
      };
}

class GenerateSpecRequest {
  final String productText;
  final String variantId;
  final IdeaVariant variant;

  const GenerateSpecRequest({
    required this.productText,
    required this.variantId,
    required this.variant,
  });

  Map<String, dynamic> toJson() => {
        'product_text': productText,
        'variant_id': variantId,
        'variant': variant.toJson(),
      };
}

class PatentSearchRequest {
  final List<String> queries;
  final List<String> keywords;
  final int limit;

  const PatentSearchRequest({
    required this.queries,
    required this.keywords,
    this.limit = 10,
  });

  Map<String, dynamic> toJson() => {
        'queries': queries,
        'keywords': keywords,
        'limit': limit,
      };
}

class ExportRequest {
  final ProductInput product;
  final IdeaVariant variant;
  final IdeaSpec spec;
  final List<PatentHit> hits;

  const ExportRequest({
    required this.product,
    required this.variant,
    required this.spec,
    required this.hits,
  });

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'variant': variant.toJson(),
        'spec': spec.toJson(),
        'hits': hits.map((h) => h.toJson()).toList(),
      };
}
