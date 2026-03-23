import 'package:coinly/core/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Transactions',
      body: Center(child: Text('Transactions page')),
    );
  }
}
