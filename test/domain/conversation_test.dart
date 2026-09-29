import 'package:aidy_mobile/domain/entities/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation exposes typed identity while preserving payload', () {
    final conversation = Conversation.fromJson({
      '_id': 'conversation-1',
      'type': 'channel',
      'name': 'neighbours',
      'joined': true,
    });

    expect(conversation.id, 'conversation-1');
    expect(conversation.type, 'channel');
    expect(conversation.displayName, 'neighbours');
    expect(conversation.joined, isTrue);
    expect(conversation.toJson()['_id'], 'conversation-1');
  });

  test('message parses typed fields and rejects missing identity', () {
    final message = ConversationMessage.fromJson({
      '_id': 'message-1',
      'body': 'On my way',
      'createdAt': '2026-09-29T10:00:00.000Z',
    });

    expect(message.id, 'message-1');
    expect(message.body, 'On my way');
    expect(message.createdAt, isNotNull);
    expect(
      () => ConversationMessage.fromJson({'body': 'missing id'}),
      throwsFormatException,
    );
  });
}
