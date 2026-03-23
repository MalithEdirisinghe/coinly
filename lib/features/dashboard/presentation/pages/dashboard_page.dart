import 'package:coinly/core/utils/currency_formatter.dart';
import 'package:coinly/core/widgets/app_toast.dart';
import 'package:coinly/app/theme/theme_cubit.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:coinly/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:coinly/features/transactions/presentation/transactions_page.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardPage extends StatelessWidget {
  static const int _recentTransactionsLimit = 5;

  const DashboardPage({super.key, required this.user});

  final AppUser user;

  String formatAmount(double amount) {
    return CurrencyFormatter.format(amount, currencyCode: user.currencyCode);
  }

  Future<void> _showAddTransactionDialog(BuildContext context) async {
    final cubit = context.read<DashboardCubit>();
    final transaction = await showDialog<_TransactionDraft>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _AddTransactionComposer(),
    );

    if (transaction == null || !context.mounted) {
      return;
    }

    await cubit.addTransaction(
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
    );
  }

  Future<bool> _confirmDeleteTransaction(
    BuildContext context,
    TransactionItem transaction,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: Text(
            'Remove "${transaction.title}" from your transaction history?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: context.appColors.textPrimary,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _openTransactionsPage(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<DashboardCubit>(),
          child: TransactionsPage(user: user),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardCubit, DashboardState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        AppToast.show(
          context,
          message: state.errorMessage!,
          type: AppToastType.error,
        );
        context.read<DashboardCubit>().clearError();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        endDrawer: _DashboardMenu(
          user: user,
          onSignOut: () => context.read<AuthCubit>().signOut(),
          onOpenAddTransaction: () => _showAddTransactionDialog(context),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Builder(
            builder: (context) {
              final colors = context.appColors;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [colors.accentDark, colors.accent]
                        : [colors.primary, colors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? colors.accentDark : colors.primary)
                          .withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () => _showAddTransactionDialog(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  label: const Text('Add Transaction'),
                ),
              );
            },
          ),
        ),
        body: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            final colors = context.appColors;
            final recentTransactions = state.transactions
                .take(_recentTransactionsLimit)
                .toList(growable: false);

            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeader(
                      appName: 'Coinly',
                      firstName: user.displayFirstName,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatAmount(state.balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Recent Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Income',
                            amount: formatAmount(state.income),
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Expense',
                            amount: formatAmount(state.expense),
                            color: colors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (state.transactions.length >
                            _recentTransactionsLimit)
                          OutlinedButton.icon(
                            onPressed: () => _openTransactionsPage(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? colors.accent
                                  : colors.primary,
                              side: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? colors.accent.withValues(alpha: 0.45)
                                    : colors.primary.withValues(alpha: 0.18),
                              ),
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? colors.accent.withValues(alpha: 0.08)
                                  : colors.primary.withValues(alpha: 0.05),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(Icons.east_rounded, size: 16),
                            label: const Text('See all'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: state.transactions.isEmpty
                          ? const Center(
                              child: Text(
                                'No transactions yet. Add your first one.',
                              ),
                            )
                          : ListView.separated(
                              itemCount: recentTransactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final transaction = recentTransactions[index];
                                final amountColor =
                                    transaction.type == TransactionType.income
                                    ? colors.accentDark
                                    : colors.error;

                                return Dismissible(
                                  key: ValueKey(transaction.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) =>
                                      _confirmDeleteTransaction(
                                        context,
                                        transaction,
                                      ),
                                  onDismissed: (_) {
                                    context
                                        .read<DashboardCubit>()
                                        .deleteTransaction(transaction.id);
                                    AppToast.show(
                                      context,
                                      message:
                                          '"${transaction.title}" deleted.',
                                      type: AppToastType.success,
                                    );
                                  },
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: colors.error,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Card(
                                    child: ListTile(
                                      title: Text(transaction.title),
                                      subtitle: Text(
                                        DateFormat.yMMMd().add_jm().format(
                                          transaction.createdAt,
                                        ),
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                      trailing: Text(
                                        '${transaction.type == TransactionType.income ? '+' : '-'}${formatAmount(transaction.amount)}',
                                        style: TextStyle(
                                          color: amountColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.appName, required this.firstName});

  final String appName;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                      tooltip: 'Menu',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Welcome back,',
          style: TextStyle(
            color: colors.textSecondary.withValues(alpha: 0.95),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstName,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DashboardMenu extends StatelessWidget {
  const _DashboardMenu({
    required this.user,
    required this.onSignOut,
    required this.onOpenAddTransaction,
  });

  final AppUser user;
  final VoidCallback onSignOut;
  final VoidCallback onOpenAddTransaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeCubit = context.read<ThemeCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPreference = context.select(
      (ThemeCubit cubit) => cubit.state.preference,
    );

    return Drawer(
      width: 304,
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Coinly',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close menu',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty
                          ? user.displayFirstName
                          : user.fullName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colors.accent.withValues(alpha: 0.16)
                            : colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? colors.accent.withValues(alpha: 0.34)
                              : colors.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        'Currency: ${user.currencyCode}',
                        style: TextStyle(
                          color: isDark ? colors.accent : colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Appearance',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ThemeModeSelector(
                currentPreference: currentPreference,
                onChanged: themeCubit.setTheme,
              ),
              const SizedBox(height: 20),
              Text(
                'Quick actions',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _MenuActionTile(
                icon: Icons.add_card_rounded,
                title: 'Add transaction',
                subtitle: 'Open the quick add form',
                onTap: () {
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => onOpenAddTransaction(),
                  );
                },
              ),
              _MenuActionTile(
                icon: Icons.logout_rounded,
                title: 'Log out',
                subtitle: 'Sign out from this account',
                onTap: () {
                  Navigator.of(context).pop();
                  onSignOut();
                },
              ),
              const Spacer(),
              Text(
                'Track spending with clarity.',
                style: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.92),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  const _MenuActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: colors.surfaceMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? colors.primaryLight : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: isDark ? Colors.white : colors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.currentPreference,
    required this.onChanged,
  });

  final AppThemePreference currentPreference;
  final ValueChanged<AppThemePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (final option in AppThemePreference.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _ThemeChoiceChip(
                  label: switch (option) {
                    AppThemePreference.system => 'System',
                    AppThemePreference.light => 'Light',
                    AppThemePreference.dark => 'Dark',
                  },
                  isSelected: option == currentPreference,
                  onTap: () => onChanged(option),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  const _ThemeChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? colors.accentDark : colors.primary)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected && isDark
            ? Border.all(color: colors.accent.withValues(alpha: 0.4))
            : null,
        boxShadow: isSelected && isDark
            ? [
                BoxShadow(
                  color: colors.accentDark.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.bar_chart, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTransactionComposer extends StatefulWidget {
  const _AddTransactionComposer();

  @override
  State<_AddTransactionComposer> createState() =>
      _AddTransactionComposerState();
}

class _AddTransactionComposerState extends State<_AddTransactionComposer> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;

  static const _expenseSuggestions = [
    'Groceries',
    'Transport',
    'Dining',
    'Bills',
  ];

  static const _incomeSuggestions = ['Salary', 'Freelance', 'Bonus', 'Refund'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _TransactionDraft(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final colors = context.appColors;
    final viewInsets = mediaQuery.viewInsets.bottom;
    final suggestions = _type == TransactionType.income
        ? _incomeSuggestions
        : _expenseSuggestions;
    final accent = _type == TransactionType.income
        ? colors.accentDark
        : colors.error;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          maxHeight: (mediaQuery.size.height - viewInsets - 48).clamp(
            320.0,
            mediaQuery.size.height,
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: (mediaQuery.size.height - viewInsets - 48).clamp(
                  320.0,
                  mediaQuery.size.height * 0.9,
                ),
              ),
              child: Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: colors.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New transaction',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Track money movement with a clean record.',
                                      style: TextStyle(
                                        color: colors.textSecondary.withValues(
                                          alpha: 0.95,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  _type == TransactionType.income
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.surfaceMuted,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _TypeChoiceButton(
                                    label: 'Expense',
                                    icon: Icons.arrow_upward_rounded,
                                    isSelected:
                                        _type == TransactionType.expense,
                                    selectedColor: colors.error,
                                    onTap: () => setState(
                                      () => _type = TransactionType.expense,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _TypeChoiceButton(
                                    label: 'Income',
                                    icon: Icons.arrow_downward_rounded,
                                    isSelected: _type == TransactionType.income,
                                    selectedColor: colors.accentDark,
                                    onTap: () => setState(
                                      () => _type = TransactionType.income,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _titleController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'e.g. Salary, Groceries, Uber',
                              prefixIcon: Icon(Icons.edit_note_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Title is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (value) {
                              final amount = double.tryParse(value ?? '');
                              if (amount == null || amount <= 0) {
                                return 'Enter a valid amount.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Quick picks',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary.withValues(
                                alpha: 0.95,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final item in suggestions)
                                ActionChip(
                                  label: Text(item),
                                  backgroundColor: accent.withValues(
                                    alpha: 0.08,
                                  ),
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.18),
                                  ),
                                  onPressed: () => _titleController.text = item,
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surfaceMuted,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.insights_rounded,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _type == TransactionType.income
                                        ? 'Income entries increase your available balance.'
                                        : 'Expense entries reduce your available balance.',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accent,
                                        accent.withValues(alpha: 0.78),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.24),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: FilledButton.icon(
                                    onPressed: _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('Save transaction'),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChoiceButton extends StatelessWidget {
  const _TypeChoiceButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionDraft {
  const _TransactionDraft({
    required this.title,
    required this.amount,
    required this.type,
  });

  final String title;
  final double amount;
  final TransactionType type;
}
