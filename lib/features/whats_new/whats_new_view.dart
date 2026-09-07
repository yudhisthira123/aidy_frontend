import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WhatsNewView extends ConsumerStatefulWidget {
  const WhatsNewView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _WhatsNewViewState();
  }
}

class _WhatsNewViewState extends ConsumerState<WhatsNewView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AIDY')),
      body: Center(child: Text('Whatsnew?')),
    );
  }
}
