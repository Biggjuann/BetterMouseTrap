class CoverSheet {
  final String inventionTitle;
  final String filingDateNote;

  const CoverSheet({
    required this.inventionTitle,
    required this.filingDateNote,
  });

  factory CoverSheet.fromJson(Map<String, dynamic> json) => CoverSheet(
        inventionTitle: json['invention_title'] as String,
        filingDateNote: json['filing_date_note'] as String,
      );
}

class Background {
  final String fieldOfInvention;
  final String descriptionOfPriorArt;

  const Background({
    required this.fieldOfInvention,
    required this.descriptionOfPriorArt,
  });

  factory Background.fromJson(Map<String, dynamic> json) => Background(
        fieldOfInvention: json['field_of_invention'] as String,
        descriptionOfPriorArt: json['description_of_prior_art'] as String,
      );
}

class Specification {
  final String titleOfInvention;
  final String? crossReference;
  final Background background;
  final String summary;
  final String? briefDescriptionOfDrawings;
  final String detailedDescription;

  const Specification({
    required this.titleOfInvention,
    this.crossReference,
    required this.background,
    required this.summary,
    this.briefDescriptionOfDrawings,
    required this.detailedDescription,
  });

  factory Specification.fromJson(Map<String, dynamic> json) => Specification(
        titleOfInvention: json['title_of_invention'] as String,
        crossReference: json['cross_reference'] as String?,
        background:
            Background.fromJson(json['background'] as Map<String, dynamic>),
        summary: json['summary'] as String,
        briefDescriptionOfDrawings:
            json['brief_description_of_drawings'] as String?,
        detailedDescription: json['detailed_description'] as String,
      );
}

class ProvisionalPatentResponse {
  final CoverSheet coverSheet;
  final Specification specification;
  final String abstract_;
  final Map<String, dynamic> claims;
  final String drawingsNote;
  final String markdown;

  const ProvisionalPatentResponse({
    required this.coverSheet,
    required this.specification,
    required this.abstract_,
    required this.claims,
    required this.drawingsNote,
    required this.markdown,
  });

  factory ProvisionalPatentResponse.fromJson(Map<String, dynamic> json) =>
      ProvisionalPatentResponse(
        coverSheet:
            CoverSheet.fromJson(json['cover_sheet'] as Map<String, dynamic>),
        specification: Specification.fromJson(
            json['specification'] as Map<String, dynamic>),
        abstract_: json['abstract'] as String,
        claims: json['claims'] as Map<String, dynamic>,
        drawingsNote: json['drawings_note'] as String,
        markdown: json['markdown'] as String,
      );
}
