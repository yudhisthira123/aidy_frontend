

/// Represents a lost/found (or help request) report
class RequestsModel {
  final String id;
  final String createdBy;
  final String requesterName;
  final String kind;
  final String mainCategory;
  final String subcategory;
  final ReportLocation location;
  final List<String> equipmentRequired;
  final String description;
  final List<String> images;
  final String contactPreference;
  final String status;
  final List<dynamic> matchedHelpers;
  final List<dynamic> helpers;
  final List<dynamic> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  RequestsModel({
    required this.id,
    required this.createdBy,
    required this.requesterName,
    required this.kind,
    required this.mainCategory,
    required this.subcategory,
    required this.location,
    required this.equipmentRequired,
    required this.description,
    required this.images,
    required this.contactPreference,
    required this.status,
    required this.matchedHelpers,
    required this.helpers,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory RequestsModel.fromJson(Map<String, dynamic> json) {
    return RequestsModel(
      id: json['_id'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      mainCategory: json['mainCategory'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      location: ReportLocation.fromJson(
        json['location'] as Map<String, dynamic>? ?? {},
      ),
      equipmentRequired: (json['equipmentRequired'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      contactPreference: json['contactPreference'] as String? ?? '',
      status: json['status'] as String? ?? '',
      matchedHelpers: json['matchedHelpers'] as List<dynamic>? ?? [],
      helpers: json['helpers'] as List<dynamic>? ?? [],
      messages: json['messages'] as List<dynamic>? ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      v: json['__v'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'createdBy': createdBy,
      'requesterName': requesterName,
      'kind': kind,
      'mainCategory': mainCategory,
      'subcategory': subcategory,
      'location': location.toJson(),
      'equipmentRequired': equipmentRequired,
      'description': description,
      'images': images,
      'contactPreference': contactPreference,
      'status': status,
      'matchedHelpers': matchedHelpers,
      'helpers': helpers,
      'messages': messages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}

/// Location info for a report: a label plus [longitude, latitude] coordinates
class ReportLocation {
  final String label;
  final double longitude;
  final double latitude;

  ReportLocation({
    required this.label,
    required this.longitude,
    required this.latitude,
  });

  factory ReportLocation.fromJson(Map<String, dynamic> json) {
    final coords = (json['coordinates'] as List<dynamic>? ?? [0, 0])
        .map((e) => (e as num).toDouble())
        .toList();
    return ReportLocation(
      label: json['label'] as String? ?? '',
      longitude: coords.isNotEmpty ? coords[0] : 0.0,
      latitude: coords.length > 1 ? coords[1] : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'coordinates': [longitude, latitude],
    };
  }
}