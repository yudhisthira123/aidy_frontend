part of "../../main.dart";

class NotificationPreferencesScreen extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic>? initial;
  const NotificationPreferencesScreen({
    super.key,
    required this.api,
    this.initial,
  });

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool enabled = true;
  Map<String, bool> kinds = {'help': true, 'lost': true, 'found': true};
  Set<String> mutedCategories = {};
  Set<String> mutedSubcategories = {};
  double maxDistanceKm = 25;
  List<Map<String, dynamic>> categories = [];
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    apply(widget.initial);
    load();
  }

  void apply(Map<String, dynamic>? value) {
    if (value == null) return;
    enabled = value['enabled'] != false;
    final incomingKinds = value['kinds'] as Map? ?? {};
    kinds = {
      'help': incomingKinds['help'] != false,
      'lost': incomingKinds['lost'] != false,
      'found': incomingKinds['found'] != false,
    };
    mutedCategories = Set<String>.from(
      value['mutedCategories'] as List? ?? const [],
    );
    mutedSubcategories = Set<String>.from(
      value['mutedSubcategories'] as List? ?? const [],
    );
    maxDistanceKm = (value['maxDistanceKm'] as num?)?.toDouble() ?? 25;
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        widget.api.request('GET', '/api/users/me/notification-preferences'),
        widget.api.request('GET', '/api/categories?include=subcategories'),
      ]);
      if (!mounted) return;
      final preferences = results[0] as Map? ?? {};
      final taxonomy = results[1] as Map? ?? {};
      setState(() {
        apply(
          Map<String, dynamic>.from(
            preferences['notificationPreferences'] as Map,
          ),
        );
        categories = (taxonomy['categories'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        error = null;
      });
    } catch (caught) {
      if (mounted) setState(() => error = caught.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final response = await widget.api.request(
        'PUT',
        '/api/users/me/notification-preferences',
        body: {
          'enabled': enabled,
          'kinds': kinds,
          'mutedCategories': mutedCategories.toList(),
          'mutedSubcategories': mutedSubcategories.toList(),
          'maxDistanceKm': maxDistanceKm,
        },
      );
      if (mounted) {
        Navigator.pop(
          context,
          Map<String, dynamic>.from(response['notificationPreferences'] as Map),
        );
      }
    } catch (caught) {
      if (mounted) setState(() => error = caught.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notification preferences')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Card(
                child: SwitchListTile(
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Nearby request alerts'),
                  subtitle: const Text(
                    'Turn all automatic nearby request notifications on or off.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Request types',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final option in const [
                ('help', 'Help requests', Icons.volunteer_activism_outlined),
                ('lost', 'Lost reports', Icons.search_outlined),
                ('found', 'Found reports', Icons.inventory_2_outlined),
              ])
                Card(
                  child: SwitchListTile(
                    value: kinds[option.$1] ?? true,
                    onChanged: enabled
                        ? (value) => setState(() => kinds[option.$1] = value)
                        : null,
                    secondary: Icon(option.$3),
                    title: Text(option.$2),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Maximum alert distance',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text('${maxDistanceKm.round()} km from your saved location'),
              Slider(
                value: maxDistanceKm.clamp(1, 50).toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                label: '${maxDistanceKm.round()} km',
                onChanged: enabled
                    ? (value) => setState(() => maxDistanceKm = value)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                'Categories and subcategories',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Muted categories still remain visible in Explore; they simply stop generating push alerts.',
              ),
              const SizedBox(height: 10),
              ...categories.map((category) {
                final id = category['id']?.toString() ?? '';
                final categoryEnabled = !mutedCategories.contains(id);
                final subcategories =
                    category['subcategories'] as List? ?? const [];
                return Card(
                  child: ExpansionTile(
                    leading: Icon(
                      id == 'lost_found'
                          ? Icons.search_rounded
                          : id == 'quick_help'
                          ? Icons.emergency_outlined
                          : Icons.handshake_outlined,
                    ),
                    title: Text(category['name'] ?? readable(id)),
                    subtitle: Text(
                      categoryEnabled ? 'Alerts enabled' : 'Muted',
                    ),
                    trailing: Switch(
                      value: categoryEnabled,
                      onChanged: enabled
                          ? (value) => setState(
                              () => value
                                  ? mutedCategories.remove(id)
                                  : mutedCategories.add(id),
                            )
                          : null,
                    ),
                    children: subcategories.map<Widget>((entry) {
                      final item = Map<String, dynamic>.from(entry as Map);
                      final subId =
                          item['id']?.toString() ??
                          item['subId']?.toString() ??
                          '';
                      final selected = !mutedSubcategories.contains(subId);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: enabled && categoryEnabled
                            ? (value) => setState(
                                () => value == true
                                    ? mutedSubcategories.remove(subId)
                                    : mutedSubcategories.add(subId),
                              )
                            : null,
                        title: Text(item['name'] ?? readable(subId)),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  ),
                );
              }),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Save notification preferences'),
                ),
              ),
            ],
          ),
  );
}
