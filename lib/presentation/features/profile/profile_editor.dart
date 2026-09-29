import 'package:flutter/material.dart' hide Text;
import 'package:geolocator/geolocator.dart';

import '../../../application/profile/profile_service.dart';
import '../../../domain/gateways/lokale_api.dart';
import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.api, required this.user});
  final LokaleApi api;
  final Map<String, dynamic> user;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final ProfileService profile = ProfileService(widget.api);
  late final TextEditingController name;
  late final TextEditingController competencies;
  late final List<Map<String, dynamic>> equipment;
  late final List<Map<String, dynamic>> places;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user['name'] ?? '');
    competencies = TextEditingController(
      text: (widget.user['competencies'] as List? ?? []).join(', '),
    );
    equipment = (widget.user['equipment'] as List? ?? [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
    places = (widget.user['places'] as List? ?? [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  }

  @override
  void dispose() {
    name.dispose();
    competencies.dispose();
    super.dispose();
  }

  Future<void> addEquipment({Map<String, dynamic>? existing}) async {
    final itemName = TextEditingController(text: existing?['name'] ?? '');
    final description = TextEditingController(
      text: existing?['description'] ?? '',
    );
    String placeId =
        existing?['placeId'] ??
        (places.isEmpty ? 'home' : places.first['key'] ?? 'home');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(existing == null ? 'Add equipment' : 'Edit equipment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: itemName,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Equipment name'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: placeId,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Available at'),
                  ),
                  items:
                      (places.isEmpty
                              ? [
                                  {'key': 'home', 'name': 'Home'},
                                ]
                              : places)
                          .map(
                            (p) => DropdownMenuItem(
                              value: '${p['key']}',
                              child: Text('${p['name'] ?? p['key']}'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => update(() => placeId = value ?? 'home'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Description'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (itemName.text.trim().isEmpty) return;
                final place = places.cast<Map<String, dynamic>?>().firstWhere(
                  (p) => p?['key'] == placeId,
                  orElse: () => null,
                );
                Navigator.pop(context, {
                  'name': itemName.text.trim(),
                  'description': description.text.trim(),
                  'placeId': placeId,
                  'place': place?['name'] ?? 'Home',
                  'available': existing?['available'] ?? true,
                  'quantity': existing?['quantity'] ?? 1,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (existing == null) {
        equipment.add(result);
      } else {
        equipment[equipment.indexOf(existing)] = result;
      }
    });
  }

  Future<void> addPlace() async {
    final placeName = TextEditingController();
    String type = 'home';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Add saved place'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: placeName,
                decoration: localizedInput(
                  context,
                  const InputDecoration(labelText: 'Place name'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: localizedInput(
                  context,
                  const InputDecoration(labelText: 'Type'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'home',
                    child: Text(context.enumLabel('home')),
                  ),
                  DropdownMenuItem(
                    value: 'work',
                    child: Text(context.enumLabel('work')),
                  ),
                  DropdownMenuItem(
                    value: 'association',
                    child: Text(context.enumLabel('association')),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(context.enumLabel('other')),
                  ),
                ],
                onChanged: (value) => update(() => type = value ?? 'other'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'name': placeName.text.trim(),
                'type': type,
              }),
              child: const Text('Capture location'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result['name']!.isEmpty) return;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to save this place.');
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(
        () => places.add({
          'key': '${result['type']}_${DateTime.now().millisecondsSinceEpoch}',
          'name': result['name'],
          'type': result['type'],
          'coordinates': [position.longitude, position.latitude],
        }),
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await profile.updateUser(widget.user['id'].toString(), {
        'name': name.text.trim(),
        'competencies': competencies.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'equipment': equipment,
        'places': places,
      });
      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit capabilities')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          decoration: localizedInput(
            context,
            const InputDecoration(labelText: 'Display name'),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: competencies,
          maxLines: 3,
          decoration: localizedInput(
            context,
            const InputDecoration(
              labelText: 'Competencies',
              helperText: 'Separate skills with commas',
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saved places',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            IconButton.filledTonal(
              onPressed: addPlace,
              icon: const Icon(Icons.add_location_alt_outlined),
              tooltip: context.tr('Add place'),
            ),
          ],
        ),
        if (places.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No saved places yet.'),
            ),
          ),
        ...places.map(
          (place) => Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(place['name'] ?? 'Place'),
              subtitle: Text('${place['type'] ?? 'other'}'),
              trailing: IconButton(
                onPressed: () => setState(() => places.remove(place)),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Equipment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            IconButton.filledTonal(
              onPressed: addEquipment,
              icon: const Icon(Icons.add),
              tooltip: context.tr('Add equipment'),
            ),
          ],
        ),
        if (equipment.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No equipment added yet.'),
            ),
          ),
        ...equipment.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.handyman_outlined),
              title: Text(item['name'] ?? 'Equipment'),
              subtitle: Text(
                '${item['place'] ?? 'Home'}${('${item['description'] ?? ''}').isEmpty ? '' : '\n${item['description']}'}',
              ),
              isThreeLine: ('${item['description'] ?? ''}').isNotEmpty,
              onTap: () => addEquipment(existing: item),
              trailing: IconButton(
                onPressed: () => setState(() => equipment.remove(item)),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: busy ? null : save,
          icon: const Icon(Icons.save_outlined),
          label: Text(busy ? 'Saving…' : 'Save profile'),
        ),
      ],
    ),
  );
}
