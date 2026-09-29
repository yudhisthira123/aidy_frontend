part of "../../main.dart";

class ProfileScreen extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>> onUser;
  final VoidCallback onLogout;
  final String notificationStatus;
  final bool notificationsEnabled;
  final Future<void> Function() onNotificationsRefresh;
  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final String language;
  final ValueChanged<String> onLanguage;
  const ProfileScreen({
    super.key,
    required this.api,
    required this.user,
    required this.onUser,
    required this.onLogout,
    required this.notificationStatus,
    required this.notificationsEnabled,
    required this.onNotificationsRefresh,
    required this.darkMode,
    required this.onDarkMode,
    required this.language,
    required this.onLanguage,
  });
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  late String state;
  late Set<String> helpTypes;
  @override
  void initState() {
    super.initState();
    state = widget.user['availability']?['state'] ?? 'available';
    helpTypes = Set<String>.from(
      widget.user['availability']?['helpTypes'] ??
          ['urgent', 'local', 'community'],
    );
  }

  Future<void> save(String v) async {
    setState(() => state = v);
    final r = await widget.api.request(
      'PATCH',
      '/api/users/${widget.user['id']}',
      body: {
        'availability': {...(widget.user['availability'] ?? {}), 'state': v},
      },
    );
    widget.onUser(Map<String, dynamic>.from(r['user']));
  }

  Future<void> editProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditor(api: widget.api, user: widget.user),
      ),
    );
    if (result != null) widget.onUser(result);
  }

  Future<void> saveHelpTypes() async {
    final r = await widget.api.request(
      'PATCH',
      '/api/users/${widget.user['id']}',
      body: {
        'availability': {
          ...(widget.user['availability'] ?? {}),
          'state': state,
          'helpTypes': helpTypes.toList(),
        },
      },
    );
    widget.onUser(Map<String, dynamic>.from(r['user']));
  }

  Future<void> deleteAccount() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your profile, requests, locations, push tokens, and matching data will be permanently removed.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr('Confirm password'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.request(
        'DELETE',
        '/api/users/me',
        body: {'password': password.text, 'confirmation': 'DELETE'},
      );
      await widget.api.clearToken();
      widget.onLogout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> testNotification() async {
    try {
      await widget.onNotificationsRefresh();
      final result = await widget.api.request(
        'POST',
        '/api/users/me/test-notification',
      );
      if (!mounted) return;
      final sent = result['sent'] ?? 0;
      final devices = result['devicesFound'] ?? 0;
      final errors = (result['errorCodes'] as List? ?? []).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent > 0
                ? 'Test notification sent to $sent device${sent == 1 ? '' : 's'}.'
                : devices == 0
                ? 'No notification device is registered for this account.'
                : 'Test delivery failed${errors.isEmpty ? '.' : ': $errors'}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> editNotificationPreferences() async {
    final preferences = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationPreferencesScreen(
          api: widget.api,
          initial: widget.user['notificationPreferences'] == null
              ? null
              : Map<String, dynamic>.from(
                  widget.user['notificationPreferences'] as Map,
                ),
        ),
      ),
    );
    if (preferences != null) {
      widget.onUser({...widget.user, 'notificationPreferences': preferences});
    }
  }

  @override
  Widget build(BuildContext c) => SafeArea(
    child: Scaffold(
      appBar: AppBar(
        title: Text(c.tr('Profile')),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: green,
            child: Text(
              (widget.user['name'] ?? 'A')[0].toUpperCase(),
              style: const TextStyle(fontSize: 28, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.user['name'] ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(widget.user['email'] ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      widget.notificationStatus.startsWith(
                            'Nearby alerts ready',
                          )
                          ? Icons.notifications_active
                          : Icons.notification_important,
                      color:
                          widget.notificationStatus.startsWith(
                            'Nearby alerts ready',
                          )
                          ? green
                          : Colors.orange,
                    ),
                    title: const Text('Nearby notifications'),
                    subtitle: Text(widget.notificationStatus),
                  ),
                  OutlinedButton.icon(
                    onPressed: testNotification,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Send a test notification'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => DeviceSettings.open('notifications'),
                    icon: Icon(
                      widget.notificationsEnabled
                          ? Icons.tune
                          : Icons.notifications_active_outlined,
                    ),
                    label: Text(
                      widget.notificationsEnabled
                          ? 'Manage notification settings'
                          : 'Turn on notifications',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: editNotificationPreferences,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Choose request alerts'),
                  ),
                ],
              ),
            ),
          ),
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.battery_saver_outlined),
                      title: Text('Background delivery'),
                      subtitle: Text(
                        'Some Android devices limit apps in the background. If alerts arrive late, allow background activity and exclude Lokale from battery restrictions. Force-stopped apps cannot receive alerts until reopened.',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => DeviceSettings.open('battery'),
                          child: const Text('Battery settings'),
                        ),
                        OutlinedButton(
                          onPressed: () => DeviceSettings.open('app'),
                          child: const Text('Background activity settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.language,
            decoration: InputDecoration(labelText: c.tr('Language')),
            items:
                const {
                      'en': 'English',
                      'de': 'Deutsch',
                      'es': 'Español',
                      'fr': 'Français',
                      'tr': 'Türkçe',
                    }.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) widget.onLanguage(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: state,
            decoration: InputDecoration(labelText: c.tr('Availability')),
            items: [
              DropdownMenuItem(
                value: 'available',
                child: Text(c.tr('Available now')),
              ),
              DropdownMenuItem(
                value: 'do_not_disturb',
                child: Text(c.tr('Do not disturb')),
              ),
              DropdownMenuItem(
                value: 'unavailable_today',
                child: Text(c.tr('Not available today')),
              ),
            ],
            onChanged: (v) => save(v!),
          ),
          const SizedBox(height: 16),
          const Text(
            'Types of help',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                {
                      'urgent': 'Urgent calls',
                      'local': 'Local help',
                      'community': 'Community',
                    }.entries
                    .map(
                      (entry) => FilterChip(
                        label: Text(c.enumLabel(entry.key)),
                        selected: helpTypes.contains(entry.key),
                        onSelected: (selected) async {
                          setState(
                            () => selected
                                ? helpTypes.add(entry.key)
                                : helpTypes.remove(entry.key),
                          );
                          await saveHelpTypes();
                        },
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 18),
          Section(
            title: c.tr('Competencies'),
            items: (widget.user['competencies'] as List? ?? [])
                .map((e) => e.toString())
                .toList(),
          ),
          const SizedBox(height: 12),
          Section(
            title: c.tr('Equipment'),
            items: (widget.user['equipment'] as List? ?? [])
                .map(
                  (e) => e is Map
                      ? '${e['name']} · ${e['place'] ?? ''}'
                      : e.toString(),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          if (widget.user['role'] == 'admin') ...[
            FilledButton.icon(
              onPressed: () => Navigator.push(
                c,
                MaterialPageRoute(
                  builder: (_) => AdminManagementScreen(api: widget.api),
                ),
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Open Admin Center'),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => EquipmentCatalog(api: widget.api),
              ),
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Browse shared equipment'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: editProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Edit User Capabilities'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: widget.darkMode,
            onChanged: widget.onDarkMode,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: const Text('Use a lower-glare appearance'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: Theme.of(context).colorScheme.surface,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Lokale 1.9.0 (16001)',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: deleteAccount,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Delete my account permanently'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ),
  );
}
