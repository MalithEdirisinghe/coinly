import 'package:coinly/app/theme/app_theme.dart';
import 'package:coinly/app/theme/theme_cubit.dart';
import 'package:coinly/app/theme/theme_preferences.dart';
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
    return RepositoryProvider(
      create: (_) => ThemePreferences(),
      child: BlocProvider(
        create: (context) =>
            ThemeCubit(preferences: context.read<ThemePreferences>())
              ..loadTheme(),
        child: _CoinlyAppView(firebaseReady: firebaseReady),
      ),
    );
  }
}

class _CoinlyAppView extends StatelessWidget {
  const _CoinlyAppView({required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Coinly',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            home: const _AnimatedSplashGate(child: _FirebaseSetupPage()),
          );
        },
      );
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => TransactionsRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthCubit(authRepository: context.read<AuthRepository>()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Coinly',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode,
              home: const _AnimatedSplashGate(child: _AuthGate()),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedSplashGate extends StatefulWidget {
  const _AnimatedSplashGate({required this.child});

  final Widget child;

  @override
  State<_AnimatedSplashGate> createState() => _AnimatedSplashGateState();
}

class _AnimatedSplashGateState extends State<_AnimatedSplashGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const _AnimatedSplashPage();
    }

    return widget.child;
  }
}

class _AnimatedSplashPage extends StatelessWidget {
  const _AnimatedSplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011738),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Image.asset(
            'assets/animate.gif',
            width: 220,
            fit: BoxFit.contain,
          ),
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
