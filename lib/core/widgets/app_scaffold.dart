import 'package:flutter/material.dart';

import 'app_top_app_bar.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopAppBar(title: title),
      body: SafeArea(minimum: const EdgeInsets.all(20), child: body),
    );
  }
}
