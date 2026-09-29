part of "../../../main.dart";

class CreateRequest extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic> category;
  final String? initialKind;
  const CreateRequest({
    super.key,
    required this.api,
    required this.category,
    this.initialKind,
  });
  @override
  State<CreateRequest> createState() => _CreateRequestState();
}

class _CreateRequestState extends State<CreateRequest> {
  late final RequestService requests = RequestService(widget.api);
  String? sub, urgency = 'immediately';
  double? lat, lon;
  bool busy = false;
  String? error;
  final description = TextEditingController(),
      place = TextEditingController(text: 'Current location'),
      period = TextEditingController(text: 'Now'),
      equipment = TextEditingController(),
      contact = TextEditingController(text: 'In-app chat');

  bool get isLostFound =>
      widget.category['id'] == 'lost_found' ||
      widget.category['type'] == 'lost_found';
  bool get isFound => widget.initialKind == 'found';
  bool get isLost => widget.initialKind == 'lost';
  Future<void> locate() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    final v = await Geolocator.getCurrentPosition();
    setState(() {
      lat = v.latitude;
      lon = v.longitude;
    });
  }

  Future<void> pickOnMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationPicker(initial: LatLng(lat ?? 52.5200, lon ?? 13.4050)),
      ),
    );
    if (result != null) {
      setState(() {
        lat = result.latitude;
        lon = result.longitude;
        place.text = 'Selected map location';
      });
    }
  }

  Future<bool> preview() async {
    if (sub == null) {
      setState(() => error = 'Select a subcategory.');
      return false;
    }
    if (lat == null || lon == null) {
      setState(() => error = 'Capture or choose a location.');
      return false;
    }
    if (description.text.trim().isEmpty) {
      setState(() => error = 'Add a clear description.');
      return false;
    }
    setState(() => error = null);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Review request'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    readable(sub),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(description.text.trim()),
                  const SizedBox(height: 12),
                  Text('Location: ${place.text}'),
                  if (!isLostFound)
                    Text(
                      'Urgency: ${context.enumLabel(urgency)} · ${period.text}',
                    ),
                  if (equipment.text.trim().isNotEmpty)
                    Text('Equipment: ${equipment.text.trim()}'),
                  if (isLostFound) Text('Contact: ${contact.text.trim()}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Edit'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send now'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> send() async {
    if (!await preview()) return;
    setState(() => busy = true);
    try {
      final created = await requests.create({
        'kind': isLostFound
            ? (widget.initialKind ??
                  (sub!.startsWith('found') ? 'found' : 'lost'))
            : 'help',
        'mainCategory': widget.category['id'],
        'subcategory': sub,
        'location': {
          'label': place.text,
          'coordinates': [lon, lat],
        },
        if (!isLostFound) 'urgency': urgency,
        if (!isLostFound) 'period': period.text,
        if (!isLostFound)
          'equipmentRequired': equipment.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
        if (isLostFound) 'contactPreference': contact.text.trim(),
        'description': description.text,
      });
      if (mounted) {
        final summary = created['notificationSummary'] as Map? ?? {};
        final sent = summary['sent'] ?? 0;
        final devices = summary['devicesFound'] ?? 0;
        final matched = summary['matchedHelpers'] ?? 0;
        final eligible = summary['eligibleRecipients'] ?? 0;
        final configured = summary['configured'] == true;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(
              sent > 0 ? Icons.notifications_active : Icons.info_outline,
              color: sent > 0 ? green : Colors.orange,
              size: 34,
            ),
            title: const Text('Request created'),
            content: Text(
              sent > 0
                  ? '$sent nearby device${sent == 1 ? '' : 's'} notified successfully.'
                  : !configured
                  ? 'The request is active, but Firebase delivery is not configured on the server.'
                  : isLostFound && eligible == 0
                  ? 'The report is active, but no nearby user has opted into this kind of alert. It remains visible in Explore.'
                  : isLostFound && devices == 0
                  ? '$eligible nearby user${eligible == 1 ? '' : 's'} matched your alert settings, but none had a registered notification device. The report remains visible in Explore.'
                  : isLostFound
                  ? 'Nearby devices were found, but push delivery failed. The report remains visible in Explore.'
                  : matched == 0
                  ? 'The request is active, but no available nearby helper matched the required skills, equipment, and help preferences.'
                  : devices == 0
                  ? '$matched nearby helper${matched == 1 ? '' : 's'} matched, but none had a registered notification device. They can still see it after refreshing their helper inbox.'
                  : 'Nearby devices were found, but push delivery failed. The request remains visible in their helper inbox.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final allSubs = (widget.category['subcategories'] as List? ?? []);
    final subs = !isLostFound || widget.initialKind == null
        ? allSubs
        : allSubs.where((item) {
            final reportKind = item['reportKind']?.toString();
            final id =
                item['id']?.toString() ?? item['subId']?.toString() ?? '';
            return reportKind == widget.initialKind ||
                id.startsWith('${widget.initialKind}_');
          }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFound
              ? 'Report something found'
              : isLost
              ? 'Report something lost'
              : widget.category['name'],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DropdownButtonFormField<String>(
            initialValue: sub,
            decoration: InputDecoration(labelText: c.tr('Subcategory')),
            items: subs
                .map<DropdownMenuItem<String>>(
                  (x) =>
                      DropdownMenuItem(value: x['id'], child: Text(x['name'])),
                )
                .toList(),
            onChanged: (v) => setState(() => sub = v),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: locate,
            icon: const Icon(Icons.my_location),
            label: Text(
              lat == null ? 'Use current location' : 'Location captured',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: pickOnMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Choose manually on map'),
          ),
          if (lat != null)
            SizedBox(
              height: 220,
              child: MapView(lat: lat!, lon: lon!),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: place,
            decoration: localizedInput(
              context,
              const InputDecoration(labelText: 'Place'),
            ),
          ),
          if (!isLostFound) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: urgency,
              decoration: InputDecoration(labelText: c.tr('Urgency')),
              items: ['immediately', 'hours', 'today', 'days', 'flexible']
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(c.enumLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => urgency = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: period,
              decoration: localizedInput(
                context,
                const InputDecoration(labelText: 'Period'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: equipment,
              decoration: localizedInput(
                context,
                const InputDecoration(
                  labelText: 'Required equipment',
                  helperText: 'Separate multiple items with commas',
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            TextField(
              controller: contact,
              decoration: localizedInput(
                context,
                const InputDecoration(labelText: 'Contact preference'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: description,
            maxLines: 4,
            decoration: localizedInput(
              context,
              const InputDecoration(labelText: 'Description'),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: busy ? null : send,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Review and send'),
            ),
          ),
        ],
      ),
    );
  }
}
