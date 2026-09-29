final class Conversation {
  Conversation._(this._data);

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Conversation requires an id.');
    }
    return Conversation._(Map<String, dynamic>.from(json));
  }

  final Map<String, dynamic> _data;

  String get id => (_data['_id'] ?? _data['id']).toString();
  String get type => _data['type']?.toString() ?? 'direct';
  String get displayName =>
      _data['displayName']?.toString() ?? _data['name']?.toString() ?? '';
  bool get joined => _data['joined'] == true;

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_data);
}

final class ConversationMessage {
  ConversationMessage._(this._data);

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Message requires an id.');
    }
    return ConversationMessage._(Map<String, dynamic>.from(json));
  }

  final Map<String, dynamic> _data;

  String get id => (_data['_id'] ?? _data['id']).toString();
  String get body => _data['body']?.toString() ?? '';
  DateTime? get createdAt =>
      DateTime.tryParse(_data['createdAt']?.toString() ?? '');

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_data);
}
