import 'package:coinly/core/constants/supported_currencies.dart';
import 'package:coinly/core/widgets/app_toast.dart';
import 'package:coinly/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _currencyCode = SupportedCurrencies.usd.code;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthState state) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cubit = context.read<AuthCubit>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (state.isLoginMode) {
      await cubit.signIn(email: email, password: password);
      return;
    }

    await cubit.signUp(
      email: email,
      password: password,
      currencyCode: _currencyCode,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(
            context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
          context.read<AuthCubit>().clearError();
        }
      },
      builder: (context, state) {
        final colors = context.appColors;
        final theme = Theme.of(context);

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Text(
                        'Coinly',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 52),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  72,
                                  24,
                                  24,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        state.isLoginMode
                                            ? 'Welcome back'
                                            : 'Create your Coinly account',
                                        style: theme.textTheme.headlineMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        state.isLoginMode
                                            ? 'Log in to sync your transactions with Firebase.'
                                            : 'Sign up to store transactions securely in Firestore.',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      if (!state.isLoginMode) ...[
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    _firstNameController,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'First name',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'Required';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _lastNameController,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Last name',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'Required';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Email is required.';
                                          }
                                          if (!value.contains('@')) {
                                            return 'Enter a valid email.';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration:
                                            const InputDecoration(
                                              labelText: 'Password',
                                              border: OutlineInputBorder(),
                                            ).copyWith(
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  );
                                                },
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                            .visibility_off_rounded
                                                      : Icons
                                                            .visibility_rounded,
                                                ),
                                              ),
                                            ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.length < 6) {
                                            return 'Password must be at least 6 characters.';
                                          }
                                          return null;
                                        },
                                      ),
                                      if (!state.isLoginMode) ...[
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          decoration:
                                              const InputDecoration(
                                                labelText: 'Confirm password',
                                                border: OutlineInputBorder(),
                                              ).copyWith(
                                                suffixIcon: IconButton(
                                                  onPressed: () {
                                                    setState(
                                                      () => _obscureConfirmPassword =
                                                          !_obscureConfirmPassword,
                                                    );
                                                  },
                                                  icon: Icon(
                                                    _obscureConfirmPassword
                                                        ? Icons
                                                              .visibility_off_rounded
                                                        : Icons
                                                              .visibility_rounded,
                                                  ),
                                                ),
                                              ),
                                          validator: (value) {
                                            if (value !=
                                                _passwordController.text) {
                                              return 'Passwords do not match.';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<String>(
                                          initialValue: _currencyCode,
                                          decoration: const InputDecoration(
                                            labelText: 'Preferred currency',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: SupportedCurrencies.values
                                              .map(
                                                (currency) => DropdownMenuItem(
                                                  value: currency.code,
                                                  child: Text(
                                                    '${currency.code} - ${currency.label}',
                                                  ),
                                                ),
                                              )
                                              .toList(growable: false),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(
                                                () => _currencyCode = value,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      FilledButton(
                                        onPressed: state.isSubmitting
                                            ? null
                                            : () => _submit(state),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          child: Text(
                                            state.isSubmitting
                                                ? 'Please wait...'
                                                : state.isLoginMode
                                                ? 'Log In'
                                                : 'Create Account',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: colors.border,
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'or',
                                              style: TextStyle(
                                                color: colors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: colors.border,
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Center(
                                        child: InkWell(
                                          onTap: state.isSubmitting
                                              ? null
                                              : () => context
                                                    .read<AuthCubit>()
                                                    .signInWithGoogle(),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          child: Opacity(
                                            opacity: state.isSubmitting
                                                ? 0.55
                                                : 1,
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: colors.surfaceMuted,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: colors.border,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: colors.shadow,
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Image.asset(
                                                  'assets/google.png',
                                                  height: 28,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: state.isSubmitting
                                            ? null
                                            : () => context
                                                  .read<AuthCubit>()
                                                  .toggleMode(),
                                        style: TextButton.styleFrom(
                                          foregroundColor: colors.textPrimary,
                                        ),
                                        child: Text(
                                          state.isLoginMode
                                              ? 'Need an account? Sign up'
                                              : 'Already have an account? Log in',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 104,
                            height: 104,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.surface,
                              border: Border.all(color: colors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow,
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

