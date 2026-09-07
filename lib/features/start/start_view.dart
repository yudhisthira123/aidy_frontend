import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StartView extends ConsumerStatefulWidget {
  const StartView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _StartViewState();
  }
}

class _StartViewState extends ConsumerState<StartView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AIDY')),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: ElevatedButton(
              onPressed: () {
                context.go('/start/quickhelp');
              },
              child: Text('Quick Help'),
            ),
          ),
          Container(
            child: ElevatedButton(
              onPressed: () {},
              child: Text('Local support'),
            ),
          ),
          Container(
            child: ElevatedButton(
              onPressed: () {},
              child: Text('Lost & Found'),
            ),
          ),
        ],
      ),
    );
  }
}
