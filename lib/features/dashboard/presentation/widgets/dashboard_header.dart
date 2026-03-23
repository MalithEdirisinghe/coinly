import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          'Your financial overview',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
