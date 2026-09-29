import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:geolocator/geolocator.dart';

import '../../../application/requests/request_service.dart';
import '../../../domain/gateways/lokale_api.dart';
import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';
import '../../shared/location_widgets.dart';
import 'request_detail.dart';
import 'helper_inbox_widgets.dart';

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
                        return NearbyHelpCard(
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
