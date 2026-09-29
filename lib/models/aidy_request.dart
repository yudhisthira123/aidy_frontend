enum AidyRequestKind {
  help,
  lost,
  found;

  static AidyRequestKind fromJson(Object? value) => switch (value) {
    'help' => AidyRequestKind.help,
    'lost' => AidyRequestKind.lost,
    'found' => AidyRequestKind.found,
    _ => throw FormatException('Unsupported request kind: $value'),
  };

  String toJson() => name;
}

class RequestLocationModel {
  final String label;
  final double longitude;
  final double latitude;

  const RequestLocationModel({
    required this.label,
    required this.longitude,
    required this.latitude,
  });

  factory RequestLocationModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'];
    if (coordinates is! List ||
        coordinates.length != 2 ||
        coordinates[0] is! num ||
        coordinates[1] is! num) {
      throw const FormatException(
        'location.coordinates must contain longitude and latitude',
      );
    }
    return RequestLocationModel(
      label: _requiredString(json, 'label'),
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
    );
  }

  List<double> get coordinates => [longitude, latitude];

  Map<String, dynamic> toJson() => {'label': label, 'coordinates': coordinates};
}

class RequestHelperModel {
  final String? id;
  final String? userId;
  final String? name;
  final String status;
  final int? etaMinutes;
  final double? distanceKm;
  final List<String> equipment;
  final List<String> competencies;
  final int additionalHelpers;
  final String? responseReason;
  final DateTime? respondedAt;
  final DateTime? acceptedNotifiedAt;
  final DateTime? nearbyNotifiedAt;
  final DateTime? lastLocationAt;
  final double? distanceToRequestMeters;

  const RequestHelperModel({
    this.id,
    this.userId,
    this.name,
    required this.status,
    this.etaMinutes,
    this.distanceKm,
    this.equipment = const [],
    this.competencies = const [],
    this.additionalHelpers = 0,
    this.responseReason,
    this.respondedAt,
    this.acceptedNotifiedAt,
    this.nearbyNotifiedAt,
    this.lastLocationAt,
    this.distanceToRequestMeters,
  });

  factory RequestHelperModel.fromJson(Map<String, dynamic> json) =>
      RequestHelperModel(
        id: _optionalString(json['_id']),
        userId: _optionalString(json['userId']),
        name: _optionalString(json['name']),
        status: _optionalString(json['status']) ?? 'notified',
        etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        equipment: _stringList(json['equipment']),
        competencies: _stringList(json['competencies']),
        additionalHelpers: (json['additionalHelpers'] as num?)?.toInt() ?? 0,
        responseReason: _optionalString(json['responseReason']),
        respondedAt: _optionalDate(json['respondedAt']),
        acceptedNotifiedAt: _optionalDate(json['acceptedNotifiedAt']),
        nearbyNotifiedAt: _optionalDate(json['nearbyNotifiedAt']),
        lastLocationAt: _optionalDate(json['lastLocationAt']),
        distanceToRequestMeters: (json['distanceToRequestMeters'] as num?)
            ?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    if (userId != null) 'userId': userId,
    if (name != null) 'name': name,
    'status': status,
    if (etaMinutes != null) 'etaMinutes': etaMinutes,
    if (distanceKm != null) 'distanceKm': distanceKm,
    'equipment': equipment,
    'competencies': competencies,
    'additionalHelpers': additionalHelpers,
    if (responseReason != null) 'responseReason': responseReason,
    if (respondedAt != null)
      'respondedAt': respondedAt!.toUtc().toIso8601String(),
    if (acceptedNotifiedAt != null)
      'acceptedNotifiedAt': acceptedNotifiedAt!.toUtc().toIso8601String(),
    if (nearbyNotifiedAt != null)
      'nearbyNotifiedAt': nearbyNotifiedAt!.toUtc().toIso8601String(),
    if (lastLocationAt != null)
      'lastLocationAt': lastLocationAt!.toUtc().toIso8601String(),
    if (distanceToRequestMeters != null)
      'distanceToRequestMeters': distanceToRequestMeters,
  };
}

class RequestMessageModel {
  final String? id;
  final String? senderId;
  final String sender;
  final String body;
  final DateTime sentAt;

  const RequestMessageModel({
    this.id,
    this.senderId,
    required this.sender,
    required this.body,
    required this.sentAt,
  });

  factory RequestMessageModel.fromJson(Map<String, dynamic> json) =>
      RequestMessageModel(
        id: _optionalString(json['_id']),
        senderId: _optionalString(json['senderId']),
        sender: _requiredString(json, 'sender'),
        body: _requiredString(json, 'body'),
        sentAt: _requiredDate(json, 'sentAt'),
      );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    if (senderId != null) 'senderId': senderId,
    'sender': sender,
    'body': body,
    'sentAt': sentAt.toUtc().toIso8601String(),
  };
}

class AidyRequestModel {
  final String id;
  final String? createdBy;
  final String requesterName;
  final AidyRequestKind kind;
  final String mainCategory;
  final String subcategory;
  final RequestLocationModel location;
  final String? urgency;
  final String? period;
  final List<String> equipmentRequired;
  final String? description;
  final List<String> images;
  final String? contactPreference;
  final String status;
  final List<String> matchedHelpers;
  final List<RequestHelperModel> helpers;
  final List<RequestMessageModel> messages;
  final DateTime? autoCloseAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const AidyRequestModel({
    required this.id,
    required this.createdBy,
    required this.requesterName,
    required this.kind,
    required this.mainCategory,
    required this.subcategory,
    required this.location,
    this.urgency,
    this.period,
    this.equipmentRequired = const [],
    this.description,
    this.images = const [],
    this.contactPreference,
    required this.status,
    this.matchedHelpers = const [],
    this.helpers = const [],
    this.messages = const [],
    this.autoCloseAt,
    required this.createdAt,
    required this.updatedAt,
    this.version = 0,
  });

  factory AidyRequestModel.fromJson(Map<String, dynamic> json) =>
      AidyRequestModel(
        id: _requiredString(json, '_id'),
        createdBy: _optionalString(json['createdBy']),
        requesterName: _optionalString(json['requesterName']) ?? 'Neighbour',
        kind: AidyRequestKind.fromJson(json['kind']),
        mainCategory: _requiredString(json, 'mainCategory'),
        subcategory: _requiredString(json, 'subcategory'),
        location: RequestLocationModel.fromJson(_requiredMap(json, 'location')),
        urgency: _optionalString(json['urgency']),
        period: _optionalString(json['period']),
        equipmentRequired: _stringList(json['equipmentRequired']),
        description: _optionalString(json['description']),
        images: _stringList(json['images']),
        contactPreference: _optionalString(json['contactPreference']),
        status: _optionalString(json['status']) ?? 'created',
        matchedHelpers: _stringList(json['matchedHelpers']),
        helpers: _modelList(json['helpers'], RequestHelperModel.fromJson),
        messages: _modelList(json['messages'], RequestMessageModel.fromJson),
        autoCloseAt: _optionalDate(json['autoCloseAt']),
        createdAt: _requiredDate(json, 'createdAt'),
        updatedAt: _requiredDate(json, 'updatedAt'),
        version: (json['__v'] as num?)?.toInt() ?? 0,
      );

  static List<AidyRequestModel> listFromJson(Object? data) {
    if (data is! List) {
      throw const FormatException(
        'Expected the requests response to be an array',
      );
    }
    return data
        .map(
          (item) =>
              AidyRequestModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'createdBy': createdBy,
    'requesterName': requesterName,
    'kind': kind.toJson(),
    'mainCategory': mainCategory,
    'subcategory': subcategory,
    'location': location.toJson(),
    'urgency': urgency,
    'period': period,
    'equipmentRequired': equipmentRequired,
    'description': description,
    'images': images,
    'contactPreference': contactPreference,
    'status': status,
    'matchedHelpers': matchedHelpers,
    'helpers': helpers.map((item) => item.toJson()).toList(growable: false),
    'messages': messages.map((item) => item.toJson()).toList(growable: false),
    'autoCloseAt': autoCloseAt?.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    '__v': version,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _optionalString(json[key]);
  if (value == null) throw FormatException('$key is required');
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('$key is required');
  return Map<String, dynamic>.from(value);
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _optionalDate(json[key]);
  if (value == null) throw FormatException('$key must be an ISO-8601 date');
  return value;
}

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

List<String> _stringList(Object? value) => value is List
    ? value.map((item) => item.toString()).toList(growable: false)
    : const [];

List<T> _modelList<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
) => value is List
    ? value
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false)
    : const [];
