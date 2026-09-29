import 'package:flutter/material.dart' hide Text;

import '../../core/app_localizations.dart';
import '../../core/localized_text.dart';
import '../../core/lokale_api.dart';

const _brand = Color(0xFF1B1D36);
const _green = Color(0xFF6757D9);

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key, required this.api});
  final LokaleApi api;

  @override
  State<AdminManagementScreen> createState() => _AdminManagementState();
}

class _AdminManagementState extends State<AdminManagementScreen> {
  static const contentLanguages = {
    'en': 'English',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
    'tr': 'Türkçe',
  };
  Map<String, Map<String, TextEditingController>> translationControllers(
    Map? existing,
  ) {
    final source = existing?['translations'] as Map? ?? {};
    final result = <String, Map<String, TextEditingController>>{};
    for (final entry in contentLanguages.entries) {
      final translated = source[entry.key] as Map?;
      result[entry.key] = {
        'name': TextEditingController(
          text:
              translated?['name'] ??
              (entry.key == 'en' ? (existing?['name'] ?? '') : ''),
        ),
        'description': TextEditingController(
          text:
              translated?['description'] ??
              (entry.key == 'en' ? (existing?['description'] ?? '') : ''),
        ),
      };
    }
    return result;
  }

  Map<String, dynamic> translationPayload(
    Map<String, Map<String, TextEditingController>> fields,
  ) => {
    for (final entry in fields.entries)
      entry.key: {
        'name': entry.value['name']!.text.trim(),
        'description': entry.value['description']!.text.trim(),
      },
  };
  Widget translationEditor(
    Map<String, Map<String, TextEditingController>> fields,
    String language,
    ValueChanged<String> select, {
    required String nameLabel,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Localized content',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const Text(
          'English is required. Empty translations use English.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: contentLanguages.entries
              .map(
                (entry) => ChoiceChip(
                  label: Text('${entry.key.toUpperCase()} · ${entry.value}'),
                  selected: language == entry.key,
                  avatar: Icon(
                    fields[entry.key]!['name']!.text.trim().isEmpty
                        ? Icons.circle_outlined
                        : Icons.check_circle,
                    size: 15,
                  ),
                  onSelected: (_) => select(entry.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: fields[language]!['name'],
          decoration: InputDecoration(
            labelText:
                '${context.tr(nameLabel)}${language == 'en' ? ' *' : ''}',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: fields[language]!['description'],
          maxLines: 2,
          decoration: localizedInput(
            context,
            const InputDecoration(labelText: 'Description'),
          ),
        ),
      ],
    ),
  );
  bool loading = true;
  int tab = 0;
  String? error;
  Map<String, dynamic> stats = {};
  List users = [], requests = [], equipment = [], categories = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await Future.wait([
        widget.api.request('GET', '/api/admin/stats'),
        widget.api.request('GET', '/api/admin/users'),
        widget.api.request('GET', '/api/admin/requests'),
        widget.api.request('GET', '/api/admin/equipment'),
        widget.api.request('GET', '/api/admin/categories'),
      ]);
      if (!mounted) return;
      setState(() {
        stats = Map<String, dynamic>.from(data[0]['stats'] ?? {});
        users = data[1]['users'] ?? [];
        requests = data[2]['requests'] ?? [];
        equipment = data[3]['equipment'] ?? [];
        categories = data[4]['categories'] ?? [];
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  Future<bool> confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> userForm([Map? existing]) async {
    final name = TextEditingController(text: existing?['name'] ?? '');
    final email = TextEditingController(text: existing?['email'] ?? '');
    final password = TextEditingController();
    String role = existing?['role'] ?? 'user';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(existing == null ? 'Add user' : 'Edit user'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Name'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Email'),
                  ),
                ),
                if (existing == null) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: localizedInput(
                      context,
                      const InputDecoration(labelText: 'Temporary password'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Role'),
                  ),
                  items: ['user', 'admin']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(context.enumLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => role = v ?? 'user'),
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
              onPressed: () => Navigator.pop(context, {
                'name': name.text.trim(),
                'email': email.text.trim(),
                if (existing == null)
                  'password': password.text.isEmpty
                      ? 'Password123'
                      : password.text,
                'role': role,
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null ||
        result['name'].toString().isEmpty ||
        result['email'].toString().isEmpty) {
      return;
    }
    try {
      await widget.api.request(
        existing == null ? 'POST' : 'PATCH',
        existing == null
            ? '/api/admin/users'
            : '/api/admin/users/${existing['id']}',
        body: result,
      );
      message(existing == null ? 'User created.' : 'User updated.');
      await load();
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> equipmentForm([Map? existing]) async {
    final localized = translationControllers(existing);
    String contentLanguage = 'en';
    final location = TextEditingController(
      text: existing?['location'] ?? 'Central Hub',
    );
    final quantity = TextEditingController(
      text: '${existing?['quantity'] ?? 1}',
    );
    String condition = existing?['condition'] ?? 'good';
    bool available = existing?['available'] ?? true;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(existing == null ? 'Add equipment' : 'Edit equipment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                translationEditor(
                  localized,
                  contentLanguage,
                  (value) => update(() => contentLanguage = value),
                  nameLabel: 'Equipment name',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: location,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Location'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Condition'),
                  ),
                  items: const ['new', 'good', 'fair', 'needs_maintenance']
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(context.enumLabel(v)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => condition = v ?? 'good'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: available,
                  title: const Text('Available'),
                  onChanged: (v) => update(() => available = v),
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
              onPressed: () => Navigator.pop(context, {
                'name': localized['en']!['name']!.text.trim(),
                'description': localized['en']!['description']!.text.trim(),
                'translations': translationPayload(localized),
                'location': location.text.trim(),
                'quantity': int.tryParse(quantity.text) ?? 1,
                'condition': condition,
                'available': available,
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result['name'].toString().isEmpty) return;
    try {
      await widget.api.request(
        existing == null ? 'POST' : 'PUT',
        existing == null
            ? '/api/admin/equipment'
            : '/api/admin/equipment/${existing['_id'] ?? existing['id']}',
        body: result,
      );
      message('Equipment saved.');
      await load();
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> categoryForm([Map? existing]) async {
    final localized = translationControllers(existing);
    String contentLanguage = 'en';
    String type = existing?['type'] ?? 'help';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(existing == null ? 'Add category' : 'Edit category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              translationEditor(
                localized,
                contentLanguage,
                (value) => update(() => contentLanguage = value),
                nameLabel: 'Category name',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: localizedInput(
                  context,
                  const InputDecoration(labelText: 'Type'),
                ),
                items: ['help', 'lost_found', 'general']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(context.enumLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => update(() => type = v ?? 'help'),
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
                'name': localized['en']!['name']!.text.trim(),
                'description': localized['en']!['description']!.text.trim(),
                'translations': translationPayload(localized),
                'type': type,
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result['name'].toString().isEmpty) return;
    try {
      await widget.api.request(
        existing == null ? 'POST' : 'PUT',
        existing == null
            ? '/api/admin/categories'
            : '/api/admin/categories/${existing['_id'] ?? existing['id']}',
        body: result,
      );
      message('Category saved.');
      await load();
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> addSubcategory(Map category) async {
    final localized = translationControllers(null);
    String contentLanguage = 'en';
    final skills = TextEditingController();
    final tools = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Add subcategory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                translationEditor(
                  localized,
                  contentLanguage,
                  (value) => update(() => contentLanguage = value),
                  nameLabel: 'Subcategory name',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: skills,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(
                      labelText: 'Required competencies',
                      helperText: 'Comma separated',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tools,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(
                      labelText: 'Required equipment',
                      helperText: 'Comma separated',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || localized['en']!['name']!.text.trim().isEmpty) return;
    List<String> csv(String value) => value
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    try {
      await widget.api.request(
        'POST',
        '/api/admin/categories/${category['_id'] ?? category['id']}/subcategories',
        body: {
          'name': localized['en']!['name']!.text.trim(),
          'translations': translationPayload(localized),
          'requiredCompetencies': csv(skills.text),
          'requiredEquipment': csv(tools.text),
        },
      );
      message('Subcategory added.');
      await load();
    } catch (e) {
      message(e.toString());
    }
  }

  Future<void> remove(String path, String label) async {
    if (!await confirm('Delete $label?', 'This action cannot be undone.')) {
      return;
    }
    try {
      await widget.api.request('DELETE', path);
      message('$label deleted.');
      await load();
    } catch (e) {
      message(e.toString());
    }
  }

  Widget empty(String text) => ListView(
    children: [
      const SizedBox(height: 180),
      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      Center(child: Text(text)),
    ],
  );
  Widget fab(VoidCallback action, String label) =>
      FloatingActionButton.extended(
        onPressed: action,
        icon: const Icon(Icons.add),
        label: Text(label),
      );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Admin Center'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
        bottom: TabBar(
          onTap: (value) => setState(() => tab = value),
          isScrollable: true,
          tabs: [
            Tab(text: context.tr('Overview')),
            Tab(text: context.tr('Users')),
            Tab(text: context.tr('Requests')),
            Tab(text: context.tr('Equipment')),
            Tab(text: context.tr('Categories')),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_brand, _green],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Lokale operations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Manage community safety from one place.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          {
                                'Users': stats['totalUsers'],
                                'Active requests': stats['activeRequests'],
                                'Equipment': stats['totalEquipment'],
                                'Categories': stats['totalCategories'],
                              }.entries
                              .map(
                                (e) => SizedBox(
                                  width: 158,
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${e.value ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              color: _brand,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(e.key),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
                users.isEmpty
                    ? empty('No users')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final u = users[i];
                          return Card(
                            child: ListTile(
                              onTap: () => userForm(u),
                              leading: CircleAvatar(
                                child: Text(
                                  '${u['name'] ?? 'U'}'[0].toUpperCase(),
                                ),
                              ),
                              title: Text(u['name'] ?? 'User'),
                              subtitle: Text('${u['email']} · ${u['role']}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') userForm(u);
                                  if (value == 'delete') {
                                    remove(
                                      '/api/admin/users/${u['id']}',
                                      'user',
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                requests.isEmpty
                    ? empty('No requests')
                    : ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: requests.length,
                        itemBuilder: (_, i) {
                          final r = requests[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.sos_outlined),
                              title: Text(
                                r['description']?.toString().isNotEmpty == true
                                    ? r['description']
                                    : r['subcategory'] ?? 'Request',
                              ),
                              subtitle: Text(
                                '${r['status']} · ${r['location']?['label'] ?? ''}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  final id = r['_id'] ?? r['id'];
                                  if (value == 'delete') {
                                    await remove(
                                      '/api/admin/requests/$id',
                                      'request',
                                    );
                                  } else {
                                    await widget.api.request(
                                      'PATCH',
                                      '/api/admin/requests/$id',
                                      body: {'status': value},
                                    );
                                    await load();
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'searching',
                                    child: Text('Mark searching'),
                                  ),
                                  PopupMenuItem(
                                    value: 'completed',
                                    child: Text('Mark completed'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                equipment.isEmpty
                    ? empty('No equipment')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                        itemCount: equipment.length,
                        itemBuilder: (_, i) {
                          final e = equipment[i];
                          return Card(
                            child: ListTile(
                              onTap: () => equipmentForm(e),
                              leading: const Icon(Icons.handyman_outlined),
                              title: Text(e['name'] ?? 'Equipment'),
                              subtitle: Text(
                                '${e['location']} · ${e['quantity']} items',
                              ),
                              trailing: IconButton(
                                onPressed: () => remove(
                                  '/api/admin/equipment/${e['_id'] ?? e['id']}',
                                  'equipment',
                                ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          );
                        },
                      ),
                categories.isEmpty
                    ? empty('No categories')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                        itemCount: categories.length,
                        itemBuilder: (_, i) {
                          final c = categories[i];
                          final subs = c['subcategories'] as List? ?? [];
                          final id = c['_id'] ?? c['id'];
                          return Card(
                            child: ExpansionTile(
                              leading: const Icon(Icons.category_outlined),
                              title: Text(c['name'] ?? 'Category'),
                              subtitle: Text('${subs.length} subcategories'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') categoryForm(c);
                                  if (v == 'add') addSubcategory(c);
                                  if (v == 'delete') {
                                    remove(
                                      '/api/admin/categories/$id',
                                      'category',
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'add',
                                    child: Text('Add subcategory'),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit category'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete category'),
                                  ),
                                ],
                              ),
                              children: subs
                                  .map(
                                    (s) => ListTile(
                                      title: Text(s['name'] ?? 'Subcategory'),
                                      trailing: IconButton(
                                        onPressed: () => remove(
                                          '/api/admin/categories/$id/subcategories/${s['_id'] ?? s['subId']}',
                                          'subcategory',
                                        ),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: tab == 1
          ? fab(userForm, 'Add user')
          : tab == 3
          ? fab(equipmentForm, 'Add equipment')
          : tab == 4
          ? fab(categoryForm, 'Add category')
          : null,
    ),
  );
}
