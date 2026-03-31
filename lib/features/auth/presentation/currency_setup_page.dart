import 'package:coinly/core/constants/supported_currencies.dart';
import 'package:coinly/core/widgets/app_toast.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:coinly/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';

class CurrencySetupPage extends StatefulWidget {
  const CurrencySetupPage({super.key, required this.user});

  final AppUser user;

  @override
  State<CurrencySetupPage> createState() => _CurrencySetupPageState();
}

class _CurrencySetupPageState extends State<CurrencySetupPage> {
  String _currencyCode = SupportedCurrencies.usd.code;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        AppToast.show(
          context,
          message: state.errorMessage!,
          type: AppToastType.error,
        );
        context.read<AuthCubit>().clearError();
      },
      child: Scaffold(
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final colors = context.appColors;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: colors.background,
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF08214A),
                          colors.background,
                        ],
                      )
                    : null,
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors.primary, colors.primaryLight],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.shadow,
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.language_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Coinly',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Set your preferred currency before entering the dashboard.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colors.surface.withValues(alpha: 0.94)
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDark
                                    ? colors.primaryLight.withValues(alpha: 0.55)
                                    : colors.border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow,
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Choose your currency',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Before you continue to Coinly, select the currency you want to use for balances and transactions.',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    height: 1.55,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Signed in as',
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.user.fullName.isEmpty
                                            ? widget.user.email
                                            : widget.user.fullName,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (widget.user.fullName.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.user.email,
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
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
                                  onChanged: state.isSubmitting
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() => _currencyCode = value);
                                          }
                                        },
                                ),
                                const SizedBox(height: 22),
                                FilledButton(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => context
                                            .read<AuthCubit>()
                                            .completeProfile(
                                              currencyCode: _currencyCode,
                                            ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Text(
                                      state.isSubmitting
                                          ? 'Saving...'
                                          : 'Continue to dashboard',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
