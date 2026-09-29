part of "../../../main.dart";

class RequestsScreen extends StatefulWidget {
  final LokaleApi api;
  const RequestsScreen({super.key, required this.api});
  @override
  State<RequestsScreen> createState() => _RequestsState();
}

class _RequestsState extends State<RequestsScreen> {
  List<Map<String, dynamic>> discovered = [];
  List<Map<String, dynamic>> mine = [];
  List<Map<String, dynamic>> categories = [];
  bool loading = true;
  bool locating = false;
  bool loadingMore = false;
  bool hasMore = false;
  String? nextCursor;
  String? error;
  String mode = 'discover';
  String kind = 'all';
  String category = 'all';
  String subcategory = 'all';
  double radiusKm = 10;
  double? latitude, longitude;
  String centerLabel = 'Choose where to search';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final results = await Future.wait([
        widget.api.getRequests(),
        widget.api.request('GET', '/api/categories?include=subcategories'),
        widget.api.request('GET', '/api/users/me/location'),
      ]);
      final owned = results[0];
      final taxonomy = results[1] as Map? ?? {};
      final locationEnvelope = results[2] as Map? ?? {};
      final location = locationEnvelope['location'] as Map?;
      if (!mounted) return;
      setState(() {
        mine =
            (owned is List<AidyRequestModel>
                    ? owned
                    : const <AidyRequestModel>[])
                .map((item) => item.toJson())
                .toList();
        categories = (taxonomy['categories'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        if (location != null) {
          latitude = (location['latitude'] as num?)?.toDouble();
          longitude = (location['longitude'] as num?)?.toDouble();
          centerLabel = 'Saved current location';
        }
        error = null;
      });
      if (latitude != null && longitude != null) await search();
    } catch (caught) {
      if (mounted) setState(() => error = caught.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> search({bool loadMore = false}) async {
    if (latitude == null || longitude == null) return;
    if (loadMore && nextCursor == null) return;
    if (loadMore && mounted) setState(() => loadingMore = true);
    try {
      final query = Uri(
        queryParameters: {
          'latitude': latitude!.toStringAsFixed(7),
          'longitude': longitude!.toStringAsFixed(7),
          'radiusKm': radiusKm.toString(),
          'kind': kind,
          'limit': '50',
          if (category != 'all') 'category': category,
          if (subcategory != 'all') 'subcategory': subcategory,
          if (loadMore && nextCursor != null) 'cursor': nextCursor!,
        },
      ).query;
      final response = await widget.api.request(
        'GET',
        '/api/requests/discover?$query',
      );
      if (!mounted) return;
      setState(() {
        final page = (response['requests'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        discovered = loadMore ? [...discovered, ...page] : page;
        final pagination = response['pagination'] as Map? ?? const {};
        hasMore = pagination['hasMore'] == true;
        nextCursor = pagination['nextCursor']?.toString();
        error = null;
      });
    } catch (caught) {
      if (mounted) setState(() => error = caught.toString());
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  Future<void> useCurrentLocation() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Turn on location services to use your current position.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required, or choose an area on the map.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await widget.api.request(
        'PUT',
        '/api/users/me/location',
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracyMeters': position.accuracy,
          'source': 'gps',
        },
      );
      if (!mounted) return;
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        centerLabel = 'Current GPS location';
      });
      await search();
    } catch (caught) {
      if (mounted) {
        setState(
          () => error = caught.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> chooseOnMap() async {
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPicker(
          initial: LatLng(latitude ?? 52.5200, longitude ?? 13.4050),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      latitude = selected.latitude;
      longitude = selected.longitude;
      centerLabel = 'Selected map area';
    });
    await search();
  }

  Map<String, dynamic>? categoryById(String id) {
    for (final category in categories) {
      if (category['id'] == id) return category;
    }
    return null;
  }

  List<Map<String, dynamic>> get filterCategories {
    if (kind == 'help') {
      return categories.where((item) => item['id'] != 'lost_found').toList();
    }
    if (kind == 'lost' || kind == 'found') {
      return categories.where((item) => item['id'] == 'lost_found').toList();
    }
    return categories;
  }

  List<Map<String, dynamic>> get filterSubcategories {
    if (category == 'all') return const [];
    final selected = categoryById(category);
    return (selected?['subcategories'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where((item) {
          final reportKind = item['reportKind']?.toString();
          final id = item['id']?.toString() ?? item['subId']?.toString() ?? '';
          if (kind == 'lost') {
            return reportKind == 'lost' || id.startsWith('lost_');
          }
          if (kind == 'found') {
            return reportKind == 'found' || id.startsWith('found_');
          }
          return true;
        })
        .toList();
  }

  bool categoryMatches(Map<String, dynamic> item) {
    if (category == 'all') return true;
    final aliases = {
      'quick_help': {'quick_help', 'help'},
      'local_support': {'local_support', 'community'},
      'lost_found': {'lost_found', 'lost'},
    };
    return (aliases[category] ?? {category}).contains(item['mainCategory']);
  }

  Future<Map<String, dynamic>?> chooseHelpCategory() async {
    final options = categories
        .where((item) => item['id'] != 'lost_found')
        .toList();
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('What kind of request?'),
              subtitle: Text('Choose urgent help or local community support.'),
            ),
            ...options.map(
              (category) => ListTile(
                leading: Icon(
                  category['id'] == 'quick_help'
                      ? Icons.emergency_outlined
                      : Icons.handshake_outlined,
                ),
                title: Text(category['name'] ?? readable(category['id'])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, category),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> create(String requestKind) async {
    Map<String, dynamic>? category;
    if (requestKind == 'help') {
      category = await chooseHelpCategory();
    } else {
      category = categoryById('lost_found');
    }
    if (category == null || !mounted) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRequest(
          api: widget.api,
          category: category!,
          initialKind: requestKind == 'help' ? null : requestKind,
        ),
      ),
    );
    if (created == true) await load();
  }

  Future<void> showCreateMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Create a post'),
              subtitle: Text(
                'Ask for help or reconnect an item or pet with its owner.',
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.volunteer_activism_outlined),
              ),
              title: const Text('Request help'),
              subtitle: const Text('Urgent or local support'),
              onTap: () => Navigator.pop(context, 'help'),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.search_outlined)),
              title: const Text('Report something lost'),
              subtitle: const Text('Pet or item you are looking for'),
              onTap: () => Navigator.pop(context, 'lost'),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.inventory_2_outlined),
              ),
              title: const Text('Report something found'),
              subtitle: const Text('Pet or item you found'),
              onTap: () => Navigator.pop(context, 'found'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await create(selected);
  }

  Future<void> openDetails(Map<String, dynamic> item) async {
    final own =
        item['isOwn'] == true ||
        mine.any((entry) => entry['_id'] == item['_id']);
    final matched = item['isMatched'] == true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetail(
          api: widget.api,
          item: item,
          canDelete: own,
          readOnly: !own && !matched,
        ),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = mode == 'discover'
        ? discovered
        : mine
              .where((item) => kind == 'all' || item['kind'] == kind)
              .where(categoryMatches)
              .where(
                (item) =>
                    subcategory == 'all' || item['subcategory'] == subcategory,
              )
              .toList();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Requests nearby'),
          actions: [
            IconButton(
              onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: context.tr('Refresh'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: showCreateMenu,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create'),
        ),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _SearchAreaCard(
                label: centerLabel,
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm,
                locating: locating,
                onCurrentLocation: useCurrentLocation,
                onChooseMap: chooseOnMap,
                onRadius: (value) async {
                  setState(() => radiusKm = value);
                  await search();
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'discover',
                    icon: Icon(Icons.explore_outlined),
                    label: Text('Explore'),
                  ),
                  ButtonSegment(
                    value: 'mine',
                    icon: Icon(Icons.person_outline),
                    label: Text('My posts'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (value) =>
                    setState(() => mode = value.first),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in const [
                      ('all', 'All'),
                      ('help', 'Help'),
                      ('lost', 'Lost'),
                      ('found', 'Found'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option.$2),
                          selected: kind == option.$1,
                          onSelected: (_) async {
                            setState(() {
                              kind = option.$1;
                              category = 'all';
                              subcategory = 'all';
                            });
                            if (mode == 'discover') await search();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey('category:$kind:$category'),
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All categories'),
                  ),
                  ...filterCategories.map(
                    (item) => DropdownMenuItem(
                      value: item['id'].toString(),
                      child: Text(item['name'] ?? readable(item['id'])),
                    ),
                  ),
                ],
                onChanged: (value) async {
                  setState(() {
                    category = value ?? 'all';
                    subcategory = 'all';
                  });
                  if (mode == 'discover') await search();
                },
              ),
              if (category != 'all' && filterSubcategories.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('subcategory:$kind:$category:$subcategory'),
                  initialValue: subcategory,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory',
                    prefixIcon: Icon(Icons.tune_rounded),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All subcategories'),
                    ),
                    ...filterSubcategories.map((item) {
                      final id =
                          item['id']?.toString() ??
                          item['subId']?.toString() ??
                          '';
                      return DropdownMenuItem(
                        value: id,
                        child: Text(item['name'] ?? readable(id)),
                      );
                    }),
                  ],
                  onChanged: (value) async {
                    setState(() => subcategory = value ?? 'all');
                    if (mode == 'discover') await search();
                  },
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                MaterialBanner(
                  content: Text(error!),
                  leading: const Icon(Icons.info_outline),
                  actions: [
                    TextButton(onPressed: load, child: const Text('Retry')),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (mode == 'discover' && latitude == null)
                _RequestEmptyState(
                  icon: Icons.location_searching_rounded,
                  title: 'Choose a search area',
                  message: 'Use your current location or select a point on the map to discover nearby posts.',
                  action: useCurrentLocation,
                  actionLabel: 'Use current location',
                )
              else if (visible.isEmpty)
                _RequestEmptyState(
                  icon: kind == 'found'
                      ? Icons.inventory_2_outlined
                      : Icons.search_off_rounded,
                  title: mode == 'mine'
                      ? 'No posts yet'
                      : 'Nothing in this area yet',
                  message: mode == 'mine'
                      ? 'Create a help, lost, or found post to see it here.'
                      : 'Try a wider radius, another category, or a different map area.',
                  action: showCreateMenu,
                  actionLabel: 'Create a post',
                )
              else
                ...visible.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DiscoveryRequestCard(
                      item: item,
                      onTap: () => openDetails(item),
                      onRespond: item['canRespond'] == true
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HelperInbox(api: widget.api),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              if (mode == 'discover' && hasMore) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: loadingMore ? null : () => search(loadMore: true),
                  icon: loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: const Text('Load more nearby requests'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAreaCard extends StatelessWidget {
  final String label;
  final double? latitude, longitude;
  final double radiusKm;
  final bool locating;
  final VoidCallback onCurrentLocation;
  final VoidCallback onChooseMap;
  final ValueChanged<double> onRadius;

  const _SearchAreaCard({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.locating,
    required this.onCurrentLocation,
    required this.onChooseMap,
    required this.onRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, .58)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar_rounded, color: Colors.white),
              SizedBox(width: 9),
              Text(
                'Search this area',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: .82)),
          ),
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: SearchAreaMap(
                key: ValueKey('$latitude:$longitude:$radiusKm'),
                lat: latitude!,
                lon: longitude!,
                radiusKm: radiusKm,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: locating ? null : onCurrentLocation,
                icon: locating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: const Text('Current'),
              ),
              FilledButton.tonalIcon(
                onPressed: onChooseMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pick on map'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: radiusKm,
                    icon: const Icon(Icons.expand_more_rounded),
                    items: const [1.0, 5.0, 10.0, 25.0, 50.0]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('${value.toInt()} km'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onRadius(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoveryRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback? onRespond;
  const _DiscoveryRequestCard({
    required this.item,
    required this.onTap,
    this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final requestKind = item['kind']?.toString() ?? 'help';
    final found = requestKind == 'found';
    final lost = requestKind == 'lost';
    final scheme = Theme.of(context).colorScheme;
    final color = found
        ? const Color(0xFF167C67)
        : lost
        ? const Color(0xFFB66A13)
        : item['urgency'] == 'immediately'
        ? coral
        : scheme.primary;
    final icon = found
        ? Icons.inventory_2_outlined
        : lost
        ? Icons.search_rounded
        : Icons.volunteer_activism_outlined;
    final distance = (item['distanceKm'] as num?)?.toDouble();
    final description = item['description']?.toString().trim() ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          readable(item['subcategory'] ?? requestKind),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${readable(requestKind)} · ${context.enumLabel(item['status'] ?? 'created')}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (item['isOwn'] == true)
                    const StatusPill(label: 'Yours', color: green)
                  else if (distance != null)
                    StatusPill(
                      label: distance < 1
                          ? '${(distance * 1000).round()} m'
                          : '${distance.toStringAsFixed(1)} km',
                      color: color,
                    ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item['location']?['label'] ?? 'Pinned location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  if (onRespond != null) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onRespond,
                      child: const Text('Respond'),
                    ),
                  ] else
                    const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;
  final String actionLabel;
  const _RequestEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
    child: Column(
      children: [
        Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: action,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(actionLabel),
        ),
      ],
    ),
  );
}
