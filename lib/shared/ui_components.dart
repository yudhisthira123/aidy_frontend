part of "../main.dart";

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});
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

class Choices extends StatefulWidget {
  final String title;
  final List<String> values;
  final Set<String> selected;
  final TextEditingController controller;
  const Choices({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.controller,
  });
  @override
  State<Choices> createState() => _ChoicesState();
}

class _ChoicesState extends State<Choices> {
  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        widget.title,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: widget.values
            .map(
              (x) => FilterChip(
                label: Text(c.tr(x)),
                selected: widget.selected.contains(x),
                onSelected: (v) => setState(
                  () => v ? widget.selected.add(x) : widget.selected.remove(x),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: widget.controller,
        decoration: localizedInput(
          c,
          InputDecoration(
            labelText: 'Add custom skill',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (widget.controller.text.trim().isNotEmpty) {
                  setState(() {
                    widget.selected.add(widget.controller.text.trim());
                    widget.controller.clear();
                  });
                }
              },
            ),
          ),
        ),
      ),
    ],
  );
}

class InfoStep extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const InfoStep({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });
  @override
  Widget build(BuildContext c) => Column(
    children: [
      Icon(icon, size: 70, color: green),
      const SizedBox(height: 16),
      Text(
        title,
        style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(text, textAlign: TextAlign.center),
    ],
  );
}

class Section extends StatelessWidget {
  final String title;
  final List<String> items;
  const Section({super.key, required this.title, required this.items});
  @override
  Widget build(BuildContext c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('None added')
          else
            ...items.map(
              (x) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline, color: green),
                title: Text(x),
              ),
            ),
        ],
      ),
    ),
  );
}
