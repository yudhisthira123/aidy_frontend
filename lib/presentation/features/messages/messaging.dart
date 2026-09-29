import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../application/messages/messaging_service.dart';
import '../../../domain/gateways/lokale_api.dart';
import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';
import 'conversation_screen.dart';

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
  late final MessagingService messaging = MessagingService(widget.api);
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
      final response = await messaging.conversations();
      if (!mounted) return;
      setState(() {
        conversations = response.map((item) => item.toJson()).toList();
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
      await messaging.createChannel(
        name: name.text.trim(),
        description: description.text.trim(),
        visibility: private ? 'private' : 'public',
        parentId: parent?['_id']?.toString(),
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
      final users = await messaging.users();
      if (!mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => PeoplePicker(users: users),
      );
      if (selected == null) return;
      final created = await messaging.startDirect(selected['id'].toString());
      if (!mounted) return;
      await openConversation(created.toJson());
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
      conversation = (await messaging.join(conversation['_id'].toString()))
          .toJson();
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
