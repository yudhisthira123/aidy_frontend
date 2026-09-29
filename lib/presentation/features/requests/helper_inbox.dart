part of "../../../main.dart";

class HelperInbox extends StatefulWidget {
  final LokaleApi api;
  const HelperInbox({super.key, required this.api});
  @override
  State<HelperInbox> createState() => _HelperInboxState();
}

class _HelperInboxState extends State<HelperInbox> {
  late final RequestService requests = RequestService(widget.api);
  List items = [];
  bool loading = true;
  String? loadError;
  final busyIds = <String>{};
  final responseErrors = <String, String>{};
  Timer? poller;
  Timer? locationTimer;
  @override
  void initState() {
    super.initState();
    load();
    poller = Timer.periodic(const Duration(seconds: 15), (_) => load());
    locationTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => updateActiveLocation(),
    );
  }

  @override
  void dispose() {
    poller?.cancel();
    locationTimer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final inbox = await requests.helperInbox();
      if (mounted) {
        setState(() {
          items = inbox;
          loadError = null;
        });
      }
      await updateActiveLocation();
    } catch (e) {
      if (mounted) setState(() => loadError = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> updateActiveLocation() async {
    final active = items.any(
      (item) => [
        'accepted',
        'on_way',
        'on_site',
      ].contains(item['helperAssignment']?['status']),
    );
    if (!active) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    await requests.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      source: 'gps',
    );
  }

  Future<void> respond(Map item, String decision, {int etaMinutes = 10}) async {
    final id = item['_id'].toString();
    setState(() {
      busyIds.add(id);
      responseErrors.remove(id);
    });
    try {
      await requests.respond(
        requestId: id,
        decision: decision,
        etaMinutes: etaMinutes,
      );
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'accept'
                  ? 'Help accepted. The requester has been notified.'
                  : 'Request declined.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => responseErrors[id] = error.toString());
    } finally {
      if (mounted) setState(() => busyIds.remove(id));
    }
  }

  Future<void> accept(Map item) async {
    var eta = 10;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirm your help'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('When do you expect to arrive?'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: eta,
                decoration: localizedInput(
                  context,
                  const InputDecoration(labelText: 'Estimated arrival'),
                ),
                items: const [5, 10, 15, 20, 30, 45, 60]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value minutes'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => eta = value ?? 10),
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
              child: const Text('Accept request'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await respond(item, 'accept', etaMinutes: eta);
  }

  Future<void> decline(Map item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline this request?'),
        content: const Text('It will be removed from your pending help list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed == true) await respond(item, 'reject');
  }

  @override
  Widget build(BuildContext c) => SafeArea(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Nearby help requests'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: loadError != null && items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 180),
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 42,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              loadError!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton.icon(
                            onPressed: load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ),
                      ],
                    )
                  : items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 220),
                        Center(child: Text('No matching requests nearby')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final requestId = item['_id'].toString();
                        final coords =
                            item['location']?['coordinates'] as List?;
                        return _NearbyHelpCard(
                          item: item,
                          busy: busyIds.contains(requestId),
                          error: responseErrors[requestId],
                          onAccept: () => accept(item),
                          onDecline: () => decline(item),
                          onDetails: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestDetail(
                                api: widget.api,
                                item: Map<String, dynamic>.from(item),
                                canDelete: false,
                              ),
                            ),
                          ),
                          onDirections: coords != null && coords.length == 2
                              ? () => openNavigation(
                                  (coords[1] as num).toDouble(),
                                  (coords[0] as num).toDouble(),
                                )
                              : null,
                        );
                      },
                    ),
            ),
    ),
  );
}

class _NearbyHelpCard extends StatelessWidget {
  final Map item;
  final bool busy;
  final String? error;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onDetails;
  final VoidCallback? onDirections;

  const _NearbyHelpCard({
    required this.item,
    required this.busy,
    required this.error,
    required this.onAccept,
    required this.onDecline,
    required this.onDetails,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final assignment = item['helperAssignment'] ?? {};
    final status = assignment['status'] ?? 'notified';
    final pending = status == 'notified';
    final urgent = item['urgency'] == 'immediately';
    final scheme = Theme.of(context).colorScheme;
    final accent = urgent ? coral : scheme.primary;
    final equipment = (item['equipmentRequired'] as List? ?? []);
    final description = item['description']?.toString().trim() ?? '';
    final distance = assignment['distanceKm'] == null
        ? null
        : (assignment['distanceKm'] as num).toDouble().toStringAsFixed(1);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    urgent
                        ? Icons.bolt_rounded
                        : Icons.volunteer_activism_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        readable(item['subcategory'] ?? 'Help request'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${readable(item['mainCategory'])} · ${context.enumLabel(item['urgency'] ?? 'flexible')}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (pending ? Colors.orange : green).withValues(
                      alpha: .12,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    pending
                        ? context.tr('New').toUpperCase()
                        : context.enumLabel(status).toUpperCase(),
                    style: TextStyle(
                      color: pending ? Colors.orange.shade800 : green,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['location']?['label'] ?? 'Pinned location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          distance == null
                              ? 'Location shared with you'
                              : '$distance km from you',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDirections != null)
                    IconButton.filledTonal(
                      tooltip: context.tr('Get directions'),
                      onPressed: onDirections,
                      icon: const Icon(Icons.near_me_rounded),
                    ),
                ],
              ),
            ),
            if (item['period']?.toString().isNotEmpty == true ||
                equipment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item['period']?.toString().isNotEmpty == true)
                    _InfoPill(
                      icon: Icons.schedule_rounded,
                      label: item['period'].toString(),
                    ),
                  if (equipment.isNotEmpty)
                    _InfoPill(
                      icon: Icons.home_repair_service_rounded,
                      label:
                          '${equipment.length} item${equipment.length == 1 ? '' : 's'} needed',
                    ),
                ],
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error!,
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (pending) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onAccept,
                  icon: const Icon(Icons.volunteer_activism_rounded),
                  label: Text(busy ? 'Sending response…' : 'I can help'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Details'),
                  ),
                ),
                if (onDirections != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Directions'),
                    ),
                  ),
                ],
              ],
            ),
            if (pending)
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: busy ? null : onDecline,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Not available'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
