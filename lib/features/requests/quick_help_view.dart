

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuickHelpView extends StatelessWidget{
  const QuickHelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quick Help'),),
      body: Center(
        child: Text('Quick Helps are here'),
      ),
    );
  }
}