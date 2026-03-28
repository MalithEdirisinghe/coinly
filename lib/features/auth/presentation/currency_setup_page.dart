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
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final colors = context.appColors;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.language_rounded,
                                color: colors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Choose your currency',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Before you continue to Coinly, select the currency you want to use for balances and transactions.',
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.user.fullName.isEmpty
                                  ? widget.user.email
                                  : widget.user.fullName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
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
                              onChanged: state.isSubmitting
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _currencyCode = value);
                                      }
                                    },
                            ),
                            const SizedBox(height: 20),
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
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
