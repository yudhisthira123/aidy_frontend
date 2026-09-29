import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../application/messages/messaging_service.dart';
import '../../../domain/gateways/lokale_api.dart';
import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';

const _violet = Color(0xFF6757D9);

class ConversationScreen extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic> conversation;
  final String currentUserId;
  const ConversationScreen({
    super.key,
    required this.api,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with WidgetsBindingObserver {
  late final MessagingService messaging = MessagingService(widget.api);
  final message = TextEditingController();
  final scroll = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  String? error;
  Timer? poller;
  bool requestInFlight = false;
  bool appActive = true;
  int pollCount = 0;
  bool hasOlder = false;
  io.Socket? socket;
  String realtimeState = 'Connecting';
  String typingName = '';
  Timer? typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load(scrollToBottom: true);
    connectRealtime();
    poller = Timer.periodic(const Duration(minutes: 2), (_) {
      pollCount += 1;
      load(incremental: pollCount % 5 != 0);
    });
  }

  void connectRealtime() {
    final conversationId = widget.conversation['_id'].toString();
    socket = io.io(
      widget.api.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': widget.api.token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    socket!.onConnect((_) {
      if (mounted) setState(() => realtimeState = 'Live');
      socket!.emit('conversation:join', conversationId);
    });
    socket!.onDisconnect((_) {
      if (mounted) setState(() => realtimeState = 'Offline');
    });
    socket!.onReconnectAttempt((_) {
      if (mounted) setState(() => realtimeState = 'Connecting');
    });
    socket!.on('conversation:message', (payload) {
      if (payload is! Map ||
          payload['conversationId'].toString() != conversationId) {
        return;
      }
      final incoming = Map<String, dynamic>.from(payload['message']);
      if (!mounted) return;
      setState(() {
        if (!messages.any(
          (item) => item['_id'].toString() == incoming['_id'].toString(),
        )) {
          messages.add(incoming);
        }
      });
      messaging.markRead(conversationId);
      WidgetsBinding.instance.addPostFrameCallback((_) => jumpToBottom());
    });
    socket!.on('conversation:message-updated', (payload) {
      if (payload is! Map ||
          payload['conversationId'].toString() != conversationId) {
        return;
      }
      final incoming = Map<String, dynamic>.from(payload['message']);
      if (mounted) {
        setState(
          () => messages = messages
              .map(
                (item) => item['_id'].toString() == incoming['_id'].toString()
                    ? incoming
                    : item,
              )
              .toList(),
        );
      }
    });
    socket!.on('conversation:typing', (payload) {
      if (payload is! Map ||
          payload['conversationId'].toString() != conversationId ||
          payload['userId'].toString() == widget.currentUserId) {
        return;
      }
      if (mounted) {
        setState(
          () => typingName = payload['typing'] == true
              ? payload['name'].toString()
              : '',
        );
      }
    });
    socket!.connect();
  }

  void messageChanged(String value) {
    final conversationId = widget.conversation['_id'].toString();
    socket?.emit('conversation:typing', {
      'conversationId': conversationId,
      'typing': value.trim().isNotEmpty,
    });
    typingTimer?.cancel();
    typingTimer = Timer(
      const Duration(milliseconds: 1200),
      () => socket?.emit('conversation:typing', {
        'conversationId': conversationId,
        'typing': false,
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appActive = state == AppLifecycleState.resumed;
    if (appActive) load(incremental: true);
  }

  @override
  void dispose() {
    poller?.cancel();
    typingTimer?.cancel();
    socket?.emit('conversation:leave', widget.conversation['_id'].toString());
    socket?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    message.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> load({
    bool scrollToBottom = false,
    bool incremental = false,
  }) async {
    if (!appActive || requestInFlight) return;
    requestInFlight = true;
    try {
      final lastMessageId = messages.isEmpty
          ? null
          : messages.last['_id']?.toString();
      final response = await messaging.messages(
        widget.conversation['_id'].toString(),
        afterId: incremental ? lastMessageId : null,
      );
      if (!mounted) return;
      final incoming = response.messages.map((item) => item.toJson()).toList();
      final initialLoad = !incremental && messages.isEmpty;
      setState(() {
        if (incremental) {
          final known = messages.map((item) => item['_id'].toString()).toSet();
          messages.addAll(
            incoming.where((item) => !known.contains(item['_id'].toString())),
          );
        } else if (initialLoad) {
          messages = incoming;
          hasOlder = response.hasMore;
        } else {
          final refreshed = {
            for (final item in incoming) item['_id'].toString(): item,
          };
          final retained = messages
              .map((item) => refreshed[item['_id'].toString()] ?? item)
              .toList();
          final known = retained.map((item) => item['_id'].toString()).toSet();
          retained.addAll(
            incoming.where((item) => !known.contains(item['_id'].toString())),
          );
          messages = retained;
        }
        error = null;
      });
      if (incoming.isNotEmpty) {
        await messaging.markRead(widget.conversation['_id'].toString());
      }
      if (scrollToBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) => jumpToBottom());
      }
    } catch (next) {
      if (mounted) setState(() => error = next.toString());
    } finally {
      requestInFlight = false;
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadOlder() async {
    if (messages.isEmpty || requestInFlight) return;
    requestInFlight = true;
    try {
      final response = await messaging.messages(
        widget.conversation['_id'].toString(),
        beforeId: messages.first['_id'].toString(),
        limit: 50,
      );
      if (!mounted) return;
      final older = response.messages.map((item) => item.toJson()).toList();
      setState(() {
        final known = messages.map((item) => item['_id'].toString()).toSet();
        messages = [
          ...older.where((item) => !known.contains(item['_id'].toString())),
          ...messages,
        ];
        hasOlder = response.hasMore;
      });
    } catch (next) {
      if (mounted) setState(() => error = next.toString());
    } finally {
      requestInFlight = false;
    }
  }

  void jumpToBottom() {
    if (scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> send() async {
    final body = message.text.trim();
    if (body.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      final sent = (await messaging.send(
        widget.conversation['_id'].toString(),
        body,
      )).toJson();
      message.clear();
      if (mounted) {
        setState(() {
          if (!messages.any(
            (item) => item['_id'].toString() == sent['_id'].toString(),
          )) {
            messages.add(sent);
          }
          error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => jumpToBottom());
      }
    } catch (next) {
      if (mounted) setState(() => error = next.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> manageMembers() async {
    try {
      final conversationId = widget.conversation['_id'].toString();
      final results = await Future.wait<List<Map<String, dynamic>>>([
        messaging.members(conversationId),
        messaging.users(),
      ]);
      if (!mounted) return;
      var members = results[0];
      final users = results[1];
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            final memberIds = members
                .map((item) => item['id'].toString())
                .toSet();
            final available = users
                .where((item) => !memberIds.contains(item['id'].toString()))
                .toList();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Channel members',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ...members.map(
                            (member) => ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  member['name'].toString()[0].toUpperCase(),
                                ),
                              ),
                              title: Text(member['name']),
                              subtitle: Text(
                                readableMessageRole(member['role']),
                              ),
                              trailing: member['role'] == 'owner'
                                  ? const Icon(Icons.workspace_premium_rounded)
                                  : IconButton(
                                      tooltip: context.tr('Remove member'),
                                      onPressed: () async {
                                        await messaging.removeMember(
                                          conversationId,
                                          member['id'].toString(),
                                        );
                                        setSheetState(
                                          () => members = members
                                              .where(
                                                (item) =>
                                                    item['id'].toString() !=
                                                    member['id'].toString(),
                                              )
                                              .toList(),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                      ),
                                    ),
                            ),
                          ),
                          if (available.isNotEmpty) ...[
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'ADD PEOPLE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            ...available.map(
                              (person) => ListTile(
                                leading: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                title: Text(person['name']),
                                onTap: () async {
                                  await messaging.addMember(
                                    conversationId,
                                    person['id'].toString(),
                                  );
                                  setSheetState(
                                    () => members = [
                                      ...members,
                                      {...person, 'role': 'member'},
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (next) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final direct = widget.conversation['type'] == 'direct';
    final title = direct
        ? widget.conversation['displayName'] ?? 'Direct message'
        : '# ${widget.conversation['name']}';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17)),
            Text(
              direct
                  ? 'Private conversation'
                  : '${widget.conversation['memberCount'] ?? 0} members · $realtimeState',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          if (widget.conversation['type'] == 'channel' &&
              [
                'owner',
                'moderator',
              ].contains(widget.conversation['membership']?['role']))
            IconButton(
              onPressed: manageMembers,
              tooltip: context.tr('Manage members'),
              icon: const Icon(Icons.group_outlined),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surfaceContainerLowest,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            if (error != null)
              MaterialBanner(
                content: Text(error!),
                actions: [
                  TextButton(onPressed: load, child: const Text('Retry')),
                ],
              ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? const Center(child: Text('No messages yet. Say hello!'))
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                      itemCount: messages.length + (hasOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (hasOlder && index == 0) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: OutlinedButton.icon(
                                onPressed: requestInFlight ? null : loadOlder,
                                icon: const Icon(
                                  Icons.history_rounded,
                                  size: 17,
                                ),
                                label: const Text('Load older messages'),
                              ),
                            ),
                          );
                        }
                        final item = messages[index - (hasOlder ? 1 : 0)];
                        final mine =
                            item['senderId'].toString() == widget.currentUserId;
                        final deleted = item['deletedAt'] != null;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 310),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(13, 9, 13, 8),
                            decoration: BoxDecoration(
                              color: mine
                                  ? _violet
                                  : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(17),
                                topRight: const Radius.circular(17),
                                bottomLeft: Radius.circular(mine ? 17 : 4),
                                bottomRight: Radius.circular(mine ? 4 : 17),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: mine
                                      ? _violet.withValues(alpha: .24)
                                      : Colors.black.withValues(alpha: .06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!mine)
                                  Text(
                                    item['senderName'] ?? 'Neighbour',
                                    style: const TextStyle(
                                      color: _violet,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  item['body'] ?? '',
                                  style: TextStyle(
                                    color: mine ? Colors.white : null,
                                    fontStyle: deleted
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _messageTime(item['createdAt']),
                                  style: TextStyle(
                                    color: mine
                                        ? Colors.white70
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (typingName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 18, bottom: 3),
                      child: Text(
                        '$typingName ${context.tr('is typing…')}',
                        style: const TextStyle(
                          color: _violet,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: message,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: direct
                                  ? context.tr('Message privately…')
                                  : '${context.tr('Message')} $title…',
                              prefixIcon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                              ),
                            ),
                            onChanged: messageChanged,
                            onSubmitted: (_) => send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            backgroundColor: _violet,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: sending ? null : send,
                          icon: sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PeoplePicker extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  const PeoplePicker({super.key, required this.users});
  @override
  State<PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends State<PeoplePicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final visible = widget.users
        .where(
          (user) => user['name'].toString().toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New direct message',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: localizedInput(
                context,
                const InputDecoration(
                  hintText: 'Search people',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final user = visible[index];
                  return ListTile(
                    onTap: () => Navigator.pop(context, user),
                    leading: CircleAvatar(
                      child: Text(user['name'].toString()[0].toUpperCase()),
                    ),
                    title: Text(user['name']),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _messageTime(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  return parsed == null ? '' : DateFormat('h:mm a').format(parsed);
}

String readableMessageRole(dynamic value) {
  final text = value?.toString() ?? 'member';
  return text[0].toUpperCase() + text.substring(1);
}
