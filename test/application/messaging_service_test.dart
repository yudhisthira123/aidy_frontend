import 'package:aidy_mobile/application/messages/messaging_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_lokale_api.dart';

void main() {
  group('MessagingService', () {
    test('maps conversation and user envelopes', () async {
      final api = FakeLokaleApi()
        ..handler = (method, path, body) async => path.endsWith('/users')
            ? {
                'users': [
                  {'id': 'user-1'},
                ],
              }
            : {
                'conversations': [
                  {'_id': 'conversation-1'},
                ],
              };
      final service = MessagingService(api);

      expect((await service.conversations()).single['_id'], 'conversation-1');
      expect((await service.users()).single['id'], 'user-1');
    });

    test('creates channel with an optional parent contract', () async {
      final api = FakeLokaleApi()..response = const {};

      await MessagingService(api).createChannel(
        name: 'first-aid',
        description: 'Local responders',
        visibility: 'private',
        parentId: 'community',
      );

      expect(api.path, '/api/conversations/channels');
      expect(api.body, {
        'name': 'first-aid',
        'description': 'Local responders',
        'visibility': 'private',
        'parentId': 'community',
      });
    });

    test('encodes incremental and older-message pagination', () async {
      final api = FakeLokaleApi()
        ..response = {
          'messages': [
            {'_id': 'message-2'},
          ],
          'pagination': {'hasMore': true},
        };
      final service = MessagingService(api);

      final page = await service.messages(
        'conversation-1',
        beforeId: 'message 1',
        limit: 50,
      );

      expect(
        api.path,
        '/api/conversations/conversation-1/messages?beforeId=message+1&limit=50',
      );
      expect(page.messages.single['_id'], 'message-2');
      expect(page.hasMore, isTrue);
    });

    test('maps sent messages and read state', () async {
      final api = FakeLokaleApi()
        ..handler = (method, path, body) async => path.endsWith('/read')
            ? const {}
            : {
                'message': {'_id': 'message-1', 'body': 'On my way'},
              };
      final service = MessagingService(api);

      final sent = await service.send('conversation-1', 'On my way');
      expect(sent['_id'], 'message-1');
      expect(api.body, {'body': 'On my way'});

      await service.markRead('conversation-1');
      expect(api.path, '/api/conversations/conversation-1/read');
    });

    test('manages channel members through stable endpoint methods', () async {
      final api = FakeLokaleApi()
        ..handler = (method, path, body) async => method == 'GET'
            ? {
                'members': [
                  {'id': 'user-1'},
                ],
              }
            : const {};
      final service = MessagingService(api);

      expect((await service.members('channel-1')).single['id'], 'user-1');
      await service.addMember('channel-1', 'user-2');
      expect(api.body, {'userId': 'user-2'});
      await service.removeMember('channel-1', 'user-2');
      expect(api.path, '/api/conversations/channel-1/members/user-2');
    });
  });
}
