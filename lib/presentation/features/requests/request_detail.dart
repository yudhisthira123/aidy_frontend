part of "../../../main.dart";

class RequestDetail extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic> item;
  final bool canDelete;
  final bool readOnly;
  const RequestDetail({
    super.key,
    required this.api,
    required this.item,
    this.canDelete = true,
    this.readOnly = false,
  });
  @override
  State<RequestDetail> createState() => _RequestDetailState();
}

class _RequestDetailState extends State<RequestDetail> {
  late final RequestService requests = RequestService(widget.api);
  final message = TextEditingController();
  late Map<String, dynamic> x;
  Timer? poller;
  @override
  void initState() {
    super.initState();
    x = widget.item;
    if (!widget.readOnly) {
      poller = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
    }
  }

  @override
  void dispose() {
    poller?.cancel();
    message.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final updated = await requests.findCurrent(
        x['_id'].toString(),
        owned: widget.canDelete,
      );
      if (updated != null && mounted) {
        final value = Map<String, dynamic>.from(updated);
        setState(() => x = value);
      }
    } catch (_) {}
  }

  Future<void> send() async {
    if (message.text.trim().isEmpty) return;
    final created = await requests.sendMessage(
      x['_id'].toString(),
      message.text.trim(),
    );
    setState(() {
      final messages = List.from(x['messages'] as List? ?? [])..add(created);
      x = {...x, 'messages': messages};
      message.clear();
    });
  }

  Future<void> remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
          'This request, its matching state, and chat history will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await requests.delete(x['_id'].toString());
    if (mounted) Navigator.pop(context);
  }

  Future<void> updateStatus(String status) async {
    try {
      final updated = await requests.updateStatus(x['_id'].toString(), status);
      if (mounted) {
        setState(() => x = Map<String, dynamic>.from(updated));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr('Request marked')} ${context.enumLabel(status).toLowerCase()}.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    final coords = x['location']?['coordinates'] as List?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request details'),
        actions: widget.canDelete
            ? [
                IconButton(
                  onPressed: remove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            x['description'] ?? x['subcategory'] ?? 'Request',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: c.enumLabel(x['status'] ?? 'created'),
                color: statusColor(x['status']),
              ),
              if (x['kind'] == 'help')
                StatusPill(
                  label: c.enumLabel(x['urgency'] ?? 'flexible'),
                  color: coral,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Category: ${readable(x['mainCategory'])}'),
          Text('Help type: ${readable(x['subcategory'])}'),
          if (x['period']?.toString().isNotEmpty == true)
            Text('When: ${x['period']}'),
          if ((x['equipmentRequired'] as List? ?? []).isNotEmpty)
            Text(
              'Equipment requested: ${(x['equipmentRequired'] as List).join(', ')}',
            ),
          if (widget.canDelete &&
              !['completed', 'auto_closed'].contains(x['status'])) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(c).brightness == Brightness.dark
                    ? Theme.of(c).colorScheme.surfaceContainerHighest
                    : softMint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage this request',
                    style: TextStyle(fontWeight: FontWeight.w800, color: brand),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep helpers informed when the situation changes.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF627178)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => updateStatus('searching'),
                          child: const Text('Keep searching'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => updateStatus('completed'),
                          icon: const Icon(Icons.check),
                          label: const Text('Complete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (coords != null && coords.length == 2) ...[
            SizedBox(
              height: 260,
              child: MapView(
                lat: (coords[1] as num).toDouble(),
                lon: (coords[0] as num).toDouble(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => openNavigation(
                (coords[1] as num).toDouble(),
                (coords[0] as num).toDouble(),
              ),
              icon: const Icon(Icons.navigation),
              label: const Text('Start navigation'),
            ),
          ],
          if (x['distanceKm'] != null) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.social_distance_rounded),
              title: const Text('Distance from your selected location'),
              subtitle: Text(
                (x['distanceKm'] as num) < 1
                    ? '${((x['distanceKm'] as num) * 1000).round()} metres away'
                    : '${(x['distanceKm'] as num).toStringAsFixed(1)} km away',
              ),
            ),
          ],
          if (widget.readOnly &&
              x['contactPreference']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.contact_phone_outlined),
              title: const Text('Contact preference'),
              subtitle: Text(x['contactPreference']),
            ),
          ],
          if (!widget.readOnly) ...[
            const SizedBox(height: 18),
            const Text(
              'Chat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...(x['messages'] as List? ?? []).map(
              (m) => ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(m['body'] ?? ''),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: message,
                    decoration: localizedInput(
                      context,
                      const InputDecoration(hintText: 'Write a message'),
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
