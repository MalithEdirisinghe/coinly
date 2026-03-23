import 'package:coinly/app/theme/app_theme.dart';
import 'package:coinly/features/auth/data/auth_repository.dart';
import 'package:coinly/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:coinly/features/auth/presentation/login_page.dart';
import 'package:coinly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:coinly/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:coinly/features/transactions/data/transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CoinlyApp extends StatelessWidget {
  const CoinlyApp({super.key, this.firebaseReady = false});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coinly',
        theme: AppTheme.lightTheme,
        home: const _FirebaseSetupPage(),
      );
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => TransactionsRepository()),
      ],
      child: BlocProvider(
        create: (context) =>
            AuthCubit(authRepository: context.read<AuthRepository>()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Coinly',
          theme: AppTheme.lightTheme,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated && state.user != null) {
          return BlocProvider(
            key: ValueKey(state.user!.id),
            create: (context) => DashboardCubit(
              transactionsRepository: context.read<TransactionsRepository>(),
              userId: state.user!.id,
            )..start(),
            child: DashboardPage(user: state.user!),
          );
        }

        return const LoginPage();
      },
    );
  }
}

class _FirebaseSetupPage extends StatelessWidget {
  const _FirebaseSetupPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coinly Setup')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase configuration is missing.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text('Add your Firebase app config files, then restart the app.'),
            SizedBox(height: 20),
            Text('Required files:'),
            SizedBox(height: 8),
            Text('- Android: google-services.json'),
            Text('- iOS/macOS: GoogleService-Info.plist'),
          ],
        ),
      ),
    );
  }
}
