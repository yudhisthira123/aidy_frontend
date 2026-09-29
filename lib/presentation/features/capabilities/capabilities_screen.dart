part of "../../../main.dart";

class CapabilitiesScreen extends StatefulWidget {
  final LokaleApi api;
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>> onDone;
  final VoidCallback onLogout;
  const CapabilitiesScreen({
    super.key,
    required this.api,
    required this.user,
    required this.onDone,
    required this.onLogout,
  });
  @override
  State<CapabilitiesScreen> createState() => _CapabilitiesState();
}

class _CapabilitiesState extends State<CapabilitiesScreen> {
  late final CapabilitiesService capabilities = CapabilitiesService(widget.api);
  int step = 1;
  bool busy = false;
  String? error;
  double? lat, lon;
  final label = TextEditingController(text: 'Home'),
      address = TextEditingController(),
      skill = TextEditingController(),
      equipment = TextEditingController();
  final skills = <String>{};
  final helpTypes = <String>{'urgent', 'local', 'community'};
  Future<void> locate() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        lat = pos.latitude;
        lon = pos.longitude;
        address.text = 'Current location';
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Map<String, dynamic> payload() => {
    'step': step,
    'primaryLocation': {
      'label': label.text,
      'address': address.text,
      'coordinates': [lon, lat],
    },
    'places': [
      {
        'key': 'home',
        'name': label.text,
        'type': 'home',
        'coordinates': [lon, lat],
      },
    ],
    'competencies': skills.toList(),
    'equipment': equipment.text.trim().isEmpty
        ? []
        : [
            {
              'name': equipment.text.trim(),
              'place': 'Home',
              'placeId': 'home',
              'available': true,
              'quantity': 1,
            },
          ],
    'availability': {'state': 'available', 'helpTypes': helpTypes.toList()},
  };
  Future<void> next() async {
    if (step == 1 && (lat == null || lon == null)) {
      setState(() => error = 'Add your current or manual location first.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await capabilities.saveProgress(payload());
      if (step < 6) {
        setState(() => step++);
      } else {
        widget.onDone(await capabilities.complete());
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> skip() async {
    widget.onDone(await capabilities.skip());
  }

  Widget content() {
    switch (step) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Where are you available?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: locate,
              icon: const Icon(Icons.my_location),
              label: const Text('Use current location'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: label,
              decoration: localizedInput(
                context,
                const InputDecoration(labelText: 'Location label'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: address,
              decoration: localizedInput(
                context,
                const InputDecoration(labelText: 'Address or landmark'),
              ),
            ),
            if (lat != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 220,
                  child: MapView(lat: lat!, lon: lon!),
                ),
              ),
          ],
        );
      case 2:
        return Choices(
          title: 'Your competencies',
          values: const [
            'First aid',
            'Technically experienced',
            'Electrician',
            'Bicycle repair',
            'Car assistance',
            'Physically strong',
          ],
          selected: skills,
          controller: skill,
        );
      case 3:
        return const InfoStep(
          icon: Icons.place,
          title: 'Saved places',
          text: 'Home is created from your primary location. More places can be added from your profile.',
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Equipment',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Text('What do you have, and where?'),
            const SizedBox(height: 16),
            TextField(
              controller: equipment,
              decoration: localizedInput(
                context,
                const InputDecoration(
                  labelText: 'Equipment name',
                  hintText: 'Standard tool set',
                ),
              ),
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Availability',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            ...['urgent', 'local', 'community'].map(
              (x) => CheckboxListTile(
                value: helpTypes.contains(x),
                title: Text(context.enumLabel(x)),
                onChanged: (v) =>
                    setState(() => v! ? helpTypes.add(x) : helpTypes.remove(x)),
              ),
            ),
          ],
        );
      default:
        return const InfoStep(
          icon: Icons.verified_user_outlined,
          title: 'Ready to help',
          text: 'Review complete. Your skills, equipment, location, and availability will be used for matching.',
        );
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('User Capabilities · $step/6'),
      actions: [TextButton(onPressed: skip, child: const Text('Skip'))],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: step / 6),
                const SizedBox(height: 28),
                content(),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : next,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      step == 6 ? 'Complete profile' : 'Save and continue',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
