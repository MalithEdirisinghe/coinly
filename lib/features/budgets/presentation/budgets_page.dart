import 'package:coinly/core/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Budgets',
      body: Center(child: Text('Budgets page')),
    );
  }
}
