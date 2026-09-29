import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/app_localizations.dart';
import '../../core/localized_text.dart';
import '../../core/lokale_api.dart';

const _brand = Color(0xFF1B1D36);
const _violet = Color(0xFF6757D9);

class MessagingScreen extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic> user;
  final ValueNotifier<String?> openedConversation;
  const MessagingScreen({
    super.key,
    required this.api,
    required this.user,
    required this.openedConversation,
  });

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> conversations = [];
  bool loading = true;
  String? error;
  Timer? poller;
  bool requestInFlight = false;
  bool appActive = true;
  io.Socket? socket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    connectRealtime();
    widget.openedConversation.addListener(openFromNotification);
    poller = Timer.periodic(const Duration(minutes: 5), (_) => load());
  }

  void connectRealtime() {
    socket = io.io(
      widget.api.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': widget.api.token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    socket!.on('conversation:updated', (_) => load());
    socket!.connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appActive = state == AppLifecycleState.resumed;
    if (appActive) load();
  }

  @override
  void dispose() {
    poller?.cancel();
    socket?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    widget.openedConversation.removeListener(openFromNotification);
    super.dispose();
  }

  Future<void> openFromNotification() async {
    final id = widget.openedConversation.value;
    if (id == null) return;
    await load();
    final matches = conversations.where((item) => item['_id'].toString() == id);
    if (matches.isNotEmpty && mounted) {
      widget.openedConversation.value = null;
      await openConversation(matches.first);
    }
  }

  Future<void> load() async {
    if (!appActive || requestInFlight) return;
    requestInFlight = true;
    try {
      final response = await widget.api.request('GET', '/api/conversations');
      if (!mounted) return;
      setState(() {
        conversations = (response['conversations'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        error = null;
      });
      if (widget.openedConversation.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          openFromNotification();
        });
      }
    } catch (next) {
      if (mounted) setState(() => error = next.toString());
    } finally {
      requestInFlight = false;
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createChannel({Map<String, dynamic>? parent}) async {
    final name = TextEditingController();
    final description = TextEditingController();
    var private = false;
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            parent == null ? 'Create a channel' : 'Create subchannel',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (parent != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text('${context.tr('Inside')} #${parent['name']}'),
                ),
              TextField(
                controller: name,
                autofocus: true,
                decoration: localizedInput(
                  context,
                  const InputDecoration(
                    labelText: 'Channel name',
                    prefixText: '# ',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 2,
                decoration: localizedInput(
                  context,
                  const InputDecoration(labelText: 'Description (optional)'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: private,
                onChanged: (value) => setDialogState(() => private = value),
                title: const Text('Private channel'),
                subtitle: const Text('Only invited members can view it'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (submit != true || name.text.trim().isEmpty) return;
    try {
      await widget.api.request(
        'POST',
        '/api/conversations/channels',
        body: {
          'name': name.text.trim(),
          'description': description.text.trim(),
          'visibility': private ? 'private' : 'public',
          if (parent != null) 'parentId': parent['_id'],
        },
      );
      await load();
    } catch (next) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.toString())));
      }
    }
  }

  Future<void> startDirectMessage() async {
    try {
      final response = await widget.api.request(
        'GET',
        '/api/conversations/users',
      );
      if (!mounted) return;
      final users = (response['users'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _PeoplePicker(users: users),
      );
      if (selected == null) return;
      final created = await widget.api.request(
        'POST',
        '/api/conversations/direct',
        body: {'userId': selected['id']},
      );
      if (!mounted) return;
      await openConversation(
        Map<String, dynamic>.from(created['conversation']),
      );
      await load();
    } catch (next) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.toString())));
      }
    }
  }

  Future<void> openConversation(Map<String, dynamic> conversation) async {
    if (conversation['type'] == 'channel' && conversation['joined'] != true) {
      final joined = await widget.api.request(
        'POST',
        '/api/conversations/${conversation['_id']}/join',
      );
      conversation = Map<String, dynamic>.from(joined['conversation']);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          api: widget.api,
          conversation: conversation,
          currentUserId: widget.user['id'].toString(),
        ),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final roots = conversations
        .where((item) => item['type'] == 'channel' && item['parentId'] == null)
        .toList();
    final directs = conversations
        .where((item) => item['type'] == 'direct')
        .toList();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.add_comment_outlined),
              onSelected: (value) =>
                  value == 'channel' ? createChannel() : startDirectMessage(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'channel',
                  child: ListTile(
                    leading: Icon(Icons.tag_rounded),
                    title: Text('New channel'),
                  ),
                ),
                PopupMenuItem(
                  value: 'direct',
                  child: ListTile(
                    leading: Icon(Icons.person_add_alt_1_rounded),
                    title: Text('New direct message'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_brand, Color(0xFF5143A8)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0x33FFFFFF),
                            child: Icon(
                              Icons.forum_rounded,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your neighbourhood, connected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Channels, subchannels and private conversations.',
                                  style: TextStyle(color: Color(0xFFDCD7FF)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const _SectionLabel('CHANNELS'),
                    if (roots.isEmpty)
                      _EmptyMessage(
                        text: 'No channels yet. Create the first one.',
                        onPressed: createChannel,
                      ),
                    ...roots.expand((channel) {
                      final children = conversations
                          .where(
                            (item) =>
                                item['type'] == 'channel' &&
                                item['parentId']?.toString() ==
                                    channel['_id'].toString(),
                          )
                          .toList();
                      return [
                        _ConversationTile(
                          conversation: channel,
                          onTap: () => openConversation(channel),
                          onAddChild:
                              channel['membership']?['role'] == 'owner' ||
                                  channel['membership']?['role'] == 'moderator'
                              ? () => createChannel(parent: channel)
                              : null,
                        ),
                        ...children.map(
                          (child) => Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: _ConversationTile(
                              conversation: child,
                              subchannel: true,
                              onTap: () => openConversation(child),
                            ),
                          ),
                        ),
                      ];
                    }),
                    const _SectionLabel('DIRECT MESSAGES'),
                    if (directs.isEmpty)
                      _EmptyMessage(
                        text: 'Start a private conversation with a neighbour.',
                        onPressed: startDirectMessage,
                      ),
                    ...directs.map(
                      (direct) => _ConversationTile(
                        conversation: direct,
                        onTap: () => openConversation(direct),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _EmptyMessage({required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: Text(text)),
          TextButton(onPressed: onPressed, child: const Text('Create')),
        ],
      ),
    ),
  );
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;
  final VoidCallback? onAddChild;
  final bool subchannel;
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    this.onAddChild,
    this.subchannel = false,
  });

  @override
  Widget build(BuildContext context) {
    final direct = conversation['type'] == 'direct';
    final last = conversation['lastMessage'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _violet.withValues(alpha: .12),
          child: Icon(
            direct
                ? Icons.person_outline_rounded
                : subchannel
                ? Icons.subdirectory_arrow_right_rounded
                : conversation['visibility'] == 'private'
                ? Icons.lock_outline_rounded
                : Icons.tag_rounded,
            color: _violet,
          ),
        ),
        title: Text(
          direct
              ? conversation['displayName'] ?? 'Direct message'
              : conversation['name'] ?? 'Channel',
          style: TextStyle(
            fontWeight: conversation['unread'] == true
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          last?['body'] ??
              conversation['description'] ??
              (conversation['joined'] == true
                  ? 'No messages yet'
                  : 'Tap to join'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onAddChild != null
            ? IconButton(
                onPressed: onAddChild,
                tooltip: context.tr('Create subchannel'),
                icon: const Icon(Icons.add_rounded),
              )
            : conversation['unread'] == true
            ? const Badge()
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

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
      widget.api.request('POST', '/api/conversations/$conversationId/read');
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
      final lastMessageId = messages.isEmpty ? null : messages.last['_id'];
      final after = incremental && lastMessageId != null
          ? '?afterId=${Uri.encodeQueryComponent(lastMessageId.toString())}'
          : '';
      final response = await widget.api.request(
        'GET',
        '/api/conversations/${widget.conversation['_id']}/messages$after',
      );
      if (!mounted) return;
      final incoming = (response['messages'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final initialLoad = !incremental && messages.isEmpty;
      setState(() {
        if (incremental) {
          final known = messages.map((item) => item['_id'].toString()).toSet();
          messages.addAll(
            incoming.where((item) => !known.contains(item['_id'].toString())),
          );
        } else if (initialLoad) {
          messages = incoming;
          hasOlder = response['pagination']?['hasMore'] == true;
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
        await widget.api.request(
          'POST',
          '/api/conversations/${widget.conversation['_id']}/read',
        );
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
      final firstId = Uri.encodeQueryComponent(
        messages.first['_id'].toString(),
      );
      final response = await widget.api.request(
        'GET',
        '/api/conversations/${widget.conversation['_id']}/messages?beforeId=$firstId&limit=50',
      );
      if (!mounted) return;
      final older = (response['messages'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      setState(() {
        final known = messages.map((item) => item['_id'].toString()).toSet();
        messages = [
          ...older.where((item) => !known.contains(item['_id'].toString())),
          ...messages,
        ];
        hasOlder = response['pagination']?['hasMore'] == true;
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
      final response = await widget.api.request(
        'POST',
        '/api/conversations/${widget.conversation['_id']}/messages',
        body: {'body': body},
      );
      message.clear();
      if (mounted) {
        setState(() {
          final sent = Map<String, dynamic>.from(response['message']);
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
      final results = await Future.wait([
        widget.api.request(
          'GET',
          '/api/conversations/${widget.conversation['_id']}/members',
        ),
        widget.api.request('GET', '/api/conversations/users'),
      ]);
      if (!mounted) return;
      var members = (results[0]['members'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final users = (results[1]['users'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
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
                                        await widget.api.request(
                                          'DELETE',
                                          '/api/conversations/${widget.conversation['_id']}/members/${member['id']}',
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
                                  await widget.api.request(
                                    'POST',
                                    '/api/conversations/${widget.conversation['_id']}/members',
                                    body: {'userId': person['id']},
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

class _PeoplePicker extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  const _PeoplePicker({required this.users});
  @override
  State<_PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends State<_PeoplePicker> {
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
