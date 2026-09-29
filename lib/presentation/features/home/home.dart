part of "../../../main.dart";

class HomeShell extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>> onUser;
  final VoidCallback onLogout;
  final String notificationStatus;
  final bool notificationsEnabled;
  final ValueNotifier<String?> notificationRequest;
  final ValueNotifier<String?> notificationConversation;
  final Future<void> Function() onNotificationsRefresh;
  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final String language;
  final ValueChanged<String> onLanguage;
  const HomeShell({
    super.key,
    required this.api,
    required this.user,
    required this.onUser,
    required this.onLogout,
    required this.notificationStatus,
    required this.notificationsEnabled,
    required this.notificationRequest,
    required this.notificationConversation,
    required this.onNotificationsRefresh,
    required this.darkMode,
    required this.onDarkMode,
    required this.language,
    required this.onLanguage,
  });
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  @override
  void initState() {
    super.initState();
    widget.notificationRequest.addListener(openNotification);
    widget.notificationConversation.addListener(openConversationNotification);
  }

  void openNotification() {
    if (widget.notificationRequest.value != null && mounted) {
      setState(
        () => tab = widget.notificationRequest.value!.startsWith('report:')
            ? 1
            : 2,
      );
    }
  }

  void openConversationNotification() {
    if (widget.notificationConversation.value != null && mounted) {
      setState(() => tab = 3);
    }
  }

  @override
  void dispose() {
    widget.notificationRequest.removeListener(openNotification);
    widget.notificationConversation.removeListener(
      openConversationNotification,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final pages = [
      Dashboard(
        key: ValueKey(widget.language),
        api: widget.api,
        user: widget.user,
        onOpenRequests: () => setState(() => tab = 1),
      ),
      RequestsScreen(api: widget.api),
      HelperInbox(api: widget.api),
      MessagingScreen(
        api: widget.api,
        user: widget.user,
        openedConversation: widget.notificationConversation,
      ),
      ProfileScreen(
        api: widget.api,
        user: widget.user,
        onUser: widget.onUser,
        onLogout: widget.onLogout,
        notificationStatus: widget.notificationStatus,
        notificationsEnabled: widget.notificationsEnabled,
        onNotificationsRefresh: widget.onNotificationsRefresh,
        darkMode: widget.darkMode,
        onDarkMode: widget.onDarkMode,
        language: widget.language,
        onLanguage: widget.onLanguage,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: c.tr('Start'),
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: c.tr('Requests'),
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            label: c.tr('Help'),
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: c.tr('Messages'),
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: c.tr('Profile'),
          ),
        ],
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic> user;
  final VoidCallback onOpenRequests;
  const Dashboard({
    super.key,
    required this.api,
    required this.user,
    required this.onOpenRequests,
  });
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List categories = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await widget.api.request(
        'GET',
        '/api/categories?include=subcategories',
      );
      if (mounted) setState(() => categories = r['categories']);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext c) => SafeArea(
    child: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Row(
            children: [
              const BrandLogo(size: 44),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Lokale',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: brand,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: widget.onOpenRequests,
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: context.tr('Requests and notifications'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [brand, Color(0xFF4B3FA5), Color(0xFF7461DC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332F275F),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('HELLO')}, ${(widget.user['name'] ?? context.tr('Neighbour')).toString().toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFFD9D1FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help is closer\nthan you think.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ask for support or lend a hand nearby.',
                  style: TextStyle(color: Color(0xFFE3DFFF), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'How can we help?',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: brand,
            ),
          ),
          const Text(
            'Choose a starting point and we’ll guide you.',
            style: TextStyle(color: Color(0xFF718087)),
          ),
          const SizedBox(height: 14),
          ...categories.map(
            (x) => CategoryCard(
              api: widget.api,
              data: Map<String, dynamic>.from(x),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : softMint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: green),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart nearby matching',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: brand,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Distance, skills, equipment and availability decide who is alerted.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF60766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.newspaper_outlined),
              ),
              title: const Text(
                'Community news',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Stories, safety notes and local updates'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewsScreen(api: widget.api)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class CategoryCard extends StatelessWidget {
  final LokaleApi api;
  final Map<String, dynamic> data;
  const CategoryCard({super.key, required this.api, required this.data});
  @override
  Widget build(BuildContext c) {
    final id = data['id'];
    final color = id == 'quick_help'
        ? Colors.red
        : id == 'local_support'
        ? Colors.blue
        : green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(c).colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(
              builder: (_) => CreateRequest(api: api, category: data),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    id == 'quick_help'
                        ? Icons.favorite
                        : id == 'local_support'
                        ? Icons.handshake
                        : Icons.search,
                    color: color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(data['description'] ?? 'Create a request'),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
