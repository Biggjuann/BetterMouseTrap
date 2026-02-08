class BomItem {
  final String item;
  final String quantity;
  final String estimatedCost;
  final String source;

  const BomItem({
    required this.item,
    required this.quantity,
    required this.estimatedCost,
    required this.source,
  });

  factory BomItem.fromJson(Map<String, dynamic> json) => BomItem(
        item: json['item'] as String,
        quantity: json['quantity'] as String,
        estimatedCost: json['estimated_cost'] as String,
        source: json['source'] as String,
      );
}

class PrototypingApproach {
  final String method;
  final String rationale;
  final Map<String, dynamic> specs;
  final List<BomItem> billOfMaterials;
  final List<String> assemblyInstructions;

  const PrototypingApproach({
    required this.method,
    required this.rationale,
    required this.specs,
    required this.billOfMaterials,
    required this.assemblyInstructions,
  });

  factory PrototypingApproach.fromJson(Map<String, dynamic> json) =>
      PrototypingApproach(
        method: json['method'] as String,
        rationale: json['rationale'] as String,
        specs: json['specs'] as Map<String, dynamic>,
        billOfMaterials: (json['bill_of_materials'] as List)
            .map((e) => BomItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        assemblyInstructions:
            List<String>.from(json['assembly_instructions'] as List),
      );
}

class PrototypingResponse {
  final List<PrototypingApproach> approaches;
  final String markdown;

  const PrototypingResponse({
    required this.approaches,
    required this.markdown,
  });

  factory PrototypingResponse.fromJson(Map<String, dynamic> json) =>
      PrototypingResponse(
        approaches: (json['approaches'] as List)
            .map((e) => PrototypingApproach.fromJson(e as Map<String, dynamic>))
            .toList(),
        markdown: json['markdown'] as String,
      );

  Map<String, dynamic> toJson() => {
        'approaches': approaches
            .map((a) => {
                  'method': a.method,
                  'rationale': a.rationale,
                  'specs': a.specs,
                  'bill_of_materials': a.billOfMaterials
                      .map((b) => {
                            'item': b.item,
                            'quantity': b.quantity,
                            'estimated_cost': b.estimatedCost,
                            'source': b.source,
                          })
                      .toList(),
                  'assembly_instructions': a.assemblyInstructions,
                })
            .toList(),
        'markdown': markdown,
      };
}
