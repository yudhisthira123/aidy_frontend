import 'package:flutter/material.dart' hide Text;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../application/requests/request_service.dart';
import '../../../domain/gateways/lokale_api.dart';
import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';
import '../../shared/location_widgets.dart';
import '../../shared/value_formatters.dart';
import 'create_request.dart';
import 'helper_inbox.dart';
import 'request_detail.dart';
import 'request_list_widgets.dart';

class RequestsScreen extends StatefulWidget {
  final LokaleApi api;
  const RequestsScreen({super.key, required this.api});
  @override
  State<RequestsScreen> createState() => _RequestsState();
}

class _RequestsState extends State<RequestsScreen> {
  late final RequestService requests = RequestService(widget.api);
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
      final overview = await requests.overview();
      final location = overview.savedLocation;
      if (!mounted) return;
      setState(() {
        mine = overview.mine.map((item) => item.toJson()).toList();
        categories = overview.categories;
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
      final page = await requests.discover({
        'latitude': latitude!.toStringAsFixed(7),
        'longitude': longitude!.toStringAsFixed(7),
        'radiusKm': radiusKm.toString(),
        'kind': kind,
        'limit': '50',
        if (category != 'all') 'category': category,
        if (subcategory != 'all') 'subcategory': subcategory,
        if (loadMore && nextCursor != null) 'cursor': nextCursor!,
      });
      if (!mounted) return;
      setState(() {
        discovered = loadMore
            ? [...discovered, ...page.requests]
            : page.requests;
        hasMore = page.hasMore;
        nextCursor = page.nextCursor;
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
      await requests.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        source: 'gps',
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
              SearchAreaCard(
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
                RequestEmptyState(
                  icon: Icons.location_searching_rounded,
                  title: 'Choose a search area',
                  message: 'Use your current location or select a point on the map to discover nearby posts.',
                  action: useCurrentLocation,
                  actionLabel: 'Use current location',
                )
              else if (visible.isEmpty)
                RequestEmptyState(
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
                    child: DiscoveryRequestCard(
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
