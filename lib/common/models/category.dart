/// Root response model
class CategoriesResponse {
  final List<Category> categories;

  CategoriesResponse({required this.categories});

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    return CategoriesResponse(
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}

/// Top-level category (e.g. "Quick call for help")
class Category {
  final String id;
  final String name;
  final String type;
  final String description;
  final List<Subcategory> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      subcategories: (json['subcategories'] as List<dynamic>? ?? [])
          .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'subcategories': subcategories.map((e) => e.toJson()).toList(),
    };
  }
}

/// Subcategory (e.g. "Medical emergency", "Lost pet")
class Subcategory {
  final String id;
  final String name;
  final List<String> requiredCompetencies;
  final List<String> requiredEquipment;

  /// Only present for lost_found subcategories ("lost" or "found")
  final String? reportKind;

  Subcategory({
    required this.id,
    required this.name,
    required this.requiredCompetencies,
    required this.requiredEquipment,
    this.reportKind,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      requiredCompetencies: (json['requiredCompetencies'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      requiredEquipment: (json['requiredEquipment'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      reportKind: json['reportKind'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'requiredCompetencies': requiredCompetencies,
      'requiredEquipment': requiredEquipment,
    };
    if (reportKind != null) {
      map['reportKind'] = reportKind;
    }
    return map;
  }
}