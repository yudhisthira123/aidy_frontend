import 'package:flutter/material.dart' hide Text;

import '../../../application/admin/admin_service.dart';
import '../../../domain/gateways/lokale_api.dart';
import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';
import '../../shared/value_formatters.dart';

const _brand = Color(0xFF1B1D36);
const _green = Color(0xFF6757D9);
const _coral = Color(0xFFFF5364);
const _softMint = Color(0xFFE5F4EF);

class _AdminStatusPill extends StatelessWidget {
  const _AdminStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );
}

class AdminCenter extends StatefulWidget {
  final LokaleApi api;
  const AdminCenter({super.key, required this.api});
  @override
  State<AdminCenter> createState() => _AdminCenterState();
}

class _AdminCenterState extends State<AdminCenter> {
  late final AdminService admin = AdminService(widget.api);
  bool loading = true;
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
      final results = await admin.load();
      if (!mounted) return;
      setState(() {
        stats = results.stats;
        users = results.users;
        requests = results.requests;
        equipment = results.equipment;
        categories = results.categories;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> changeRole(Map user) async {
    final role = user['role'] == 'admin' ? 'user' : 'admin';
    await admin.changeUserRole(user['id'].toString(), role);
    await load();
  }

  Future<void> deleteRequest(Map request) async {
    await admin.delete(
      AdminResource.requests,
      (request['_id'] ?? request['id']).toString(),
    );
    await load();
  }

  Widget countCard(String label, dynamic value, IconData icon, Color color) =>
      SizedBox(
        width: 158,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 14),
                Text(
                  '${value ?? 0}',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: _brand,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF68777C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Admin Center'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
        bottom: TabBar(
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
                child: Text(error!, textAlign: TextAlign.center),
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
                          colors: [_brand, Color(0xFF166554)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Lokale operations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Monitor people, requests and community resources.',
                            style: TextStyle(color: Color(0xFFD0E3DD)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        countCard(
                          'Users',
                          stats['totalUsers'],
                          Icons.people_outline,
                          _green,
                        ),
                        countCard(
                          'Active requests',
                          stats['activeRequests'],
                          Icons.sos_outlined,
                          _coral,
                        ),
                        countCard(
                          'Equipment',
                          stats['totalEquipment'],
                          Icons.handyman_outlined,
                          const Color(0xFF3977D4),
                        ),
                        countCard(
                          'Categories',
                          stats['totalCategories'],
                          Icons.category_outlined,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
                RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u = users[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                  : _softMint,
                              child: Text(
                                '${u['name'] ?? 'U'}'[0].toUpperCase(),
                              ),
                            ),
                            title: Text(
                              u['name'] ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${u['email'] ?? ''}\n${readable(u['role'] ?? 'user')}',
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton(
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'role',
                                  child: Text(
                                    u['role'] == 'admin'
                                        ? 'Make user'
                                        : 'Make admin',
                                  ),
                                ),
                              ],
                              onSelected: (_) => changeRole(u),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: requests.length,
                    itemBuilder: (_, i) {
                      final r = requests[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.assignment_outlined,
                              color: _coral,
                            ),
                            title: Text(
                              r['title'] ??
                                  readable(r['subcategory'] ?? 'Help request'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${readable(r['category'] ?? '')} · ${readable(r['status'] ?? 'created')}',
                            ),
                            trailing: IconButton(
                              tooltip: context.tr('Delete request'),
                              onPressed: () => deleteRequest(r),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: equipment.length,
                    itemBuilder: (_, i) {
                      final e = equipment[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.handyman_outlined,
                              color: _green,
                            ),
                            title: Text(
                              e['name'] ?? 'Equipment',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${e['location'] ?? 'No location'} · ${e['quantity'] ?? 1} available',
                            ),
                            trailing: _AdminStatusPill(
                              label: e['available'] == false
                                  ? 'Unavailable'
                                  : 'Available',
                              color: e['available'] == false
                                  ? Colors.orange
                                  : _green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final subs = cat['subcategories'] as List? ?? [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ExpansionTile(
                            leading: const Icon(
                              Icons.category_outlined,
                              color: Color(0xFF3977D4),
                            ),
                            title: Text(
                              cat['name'] ?? 'Category',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text('${subs.length} subcategories'),
                            children: subs
                                .map(
                                  (s) => ListTile(
                                    dense: true,
                                    title: Text(
                                      s['name'] ?? readable(s['subId'] ?? ''),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    ),
  );
}
