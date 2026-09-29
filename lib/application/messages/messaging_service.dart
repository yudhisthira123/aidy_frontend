import '../../domain/gateways/lokale_api.dart';
import '../../domain/entities/conversation.dart';

final class MessagePage {
  const MessagePage({required this.messages, required this.hasMore});

  final List<ConversationMessage> messages;
  final bool hasMore;
}

/// Centralizes messaging HTTP contracts while realtime socket lifecycle remains
/// in presentation, where it follows application and screen lifecycle events.
final class MessagingService {
  MessagingService(this._api);

  final LokaleApi _api;

  Future<List<Conversation>> conversations() async => _items(
    await _api.request('GET', '/api/conversations'),
    'conversations',
  ).map(Conversation.fromJson).toList(growable: false);

  Future<List<Map<String, dynamic>>> users() async =>
      _items(await _api.request('GET', '/api/conversations/users'), 'users');

  Future<void> createChannel({
    required String name,
    required String description,
    required String visibility,
    String? parentId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'visibility': visibility,
    };
    if (parentId != null) {
      body['parentId'] = parentId;
    }
    await _api.request('POST', '/api/conversations/channels', body: body);
  }

  Future<Conversation> startDirect(String userId) async {
    final response = await _api.request(
      'POST',
      '/api/conversations/direct',
      body: {'userId': userId},
    );
    return Conversation.fromJson(
      Map<String, dynamic>.from(response['conversation'] as Map),
    );
  }

  Future<Conversation> join(String conversationId) async {
    final response = await _api.request(
      'POST',
      '/api/conversations/$conversationId/join',
    );
    return Conversation.fromJson(
      Map<String, dynamic>.from(response['conversation'] as Map),
    );
  }

  Future<MessagePage> messages(
    String conversationId, {
    String? afterId,
    String? beforeId,
    int? limit,
  }) async {
    final parameters = <String, String>{};
    if (afterId != null) parameters['afterId'] = afterId;
    if (beforeId != null) parameters['beforeId'] = beforeId;
    if (limit != null) parameters['limit'] = '$limit';
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    final response = await _api.request(
      'GET',
      '/api/conversations/$conversationId/messages$query',
    );
    return MessagePage(
      messages: _items(
        response,
        'messages',
      ).map(ConversationMessage.fromJson).toList(growable: false),
      hasMore: response['pagination']?['hasMore'] == true,
    );
  }

  Future<ConversationMessage> send(String conversationId, String body) async {
    final response = await _api.request(
      'POST',
      '/api/conversations/$conversationId/messages',
      body: {'body': body},
    );
    return ConversationMessage.fromJson(
      Map<String, dynamic>.from(response['message'] as Map),
    );
  }

  Future<void> markRead(String conversationId) async {
    await _api.request('POST', '/api/conversations/$conversationId/read');
  }

  Future<List<Map<String, dynamic>>> members(String conversationId) async =>
      _items(
        await _api.request('GET', '/api/conversations/$conversationId/members'),
        'members',
      );

  Future<void> addMember(String conversationId, String userId) async {
    await _api.request(
      'POST',
      '/api/conversations/$conversationId/members',
      body: {'userId': userId},
    );
  }

  Future<void> removeMember(String conversationId, String userId) async {
    await _api.request(
      'DELETE',
      '/api/conversations/$conversationId/members/$userId',
    );
  }

  List<Map<String, dynamic>> _items(dynamic response, String key) =>
      (response[key] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
}
