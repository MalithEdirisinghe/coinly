import 'package:coinly/core/utils/currency_formatter.dart';
import 'package:coinly/core/constants/transaction_categories.dart';
import 'package:coinly/core/widgets/app_top_app_bar.dart';
import 'package:coinly/core/widgets/app_toast.dart';
import 'package:coinly/core/widgets/app_confirm_dialog.dart';
import 'package:coinly/core/widgets/transaction_category_avatar.dart';
import 'package:coinly/app/theme/theme_cubit.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:coinly/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:coinly/features/categories/data/categories_repository.dart';
import 'package:coinly/features/categories/presentation/categories_page.dart';
import 'package:coinly/features/transactions/presentation/transactions_page.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.user});

  final AppUser user;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const int _recentTransactionsLimit = 5;

  AppUser get user => widget.user;

  int _currentIndex = 0;
  bool _isEndDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String formatAmount(double amount) {
    return CurrencyFormatter.format(amount, currencyCode: user.currencyCode);
  }

  Future<void> _showAddTransactionDialog(BuildContext context) async {
    final cubit = context.read<DashboardCubit>();
    final transaction = await showDialog<_TransactionDraft>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AddTransactionComposer(userId: user.id),
    );

    if (transaction == null || !context.mounted) {
      return;
    }

    await cubit.addTransaction(
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      categoryLabel: transaction.categoryLabel,
      categoryIconKey: transaction.categoryIconKey,
    );
  }

  Future<bool> _confirmDeleteTransaction(
    BuildContext context,
    TransactionItem transaction,
  ) async {
    return AppConfirmDialog.show(
      context,
      title: 'Delete transaction?',
      message: 'Remove "${transaction.title}" from your transaction history?',
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await AppConfirmDialog.show(
      context,
      title: 'Log out?',
      message: 'Are you sure you want to sign out of Coinly?',
      confirmLabel: 'Log out',
    );
    if (!shouldSignOut || !context.mounted) {
      return;
    }
    await context.read<AuthCubit>().signOut();
  }

  void _selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() => _currentIndex = index);
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
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        endDrawer: _DashboardMenu(
          user: user,
          onSignOut: () => _confirmSignOut(context),
          onOpenAddTransaction: () => _showAddTransactionDialog(context),
          onOpenManageCategories: () => _selectTab(3),
        ),
        floatingActionButton: _isEndDrawerOpen || _currentIndex != 0
            ? null
            : _BottomAddButton(
                onTap: () => _showAddTransactionDialog(context),
              ),
        onEndDrawerChanged: (isOpened) {
          if (_isEndDrawerOpen == isOpened) {
            return;
          }
          setState(() => _isEndDrawerOpen = isOpened);
        },
        bottomNavigationBar: _DashboardBottomNav(
          currentIndex: _currentIndex,
          onTap: _selectTab,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _DashboardHomeTab(
              user: user,
              recentTransactionsLimit: _recentTransactionsLimit,
              formatAmount: formatAmount,
              onOpenTransactions: () => _selectTab(1),
              onOpenExpenseTracking: () => _selectTab(2),
              onOpenMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
              onConfirmDeleteTransaction: _confirmDeleteTransaction,
            ),
            TransactionsPage(user: user),
            BlocProvider.value(
              value: context.read<DashboardCubit>(),
              child: ExpenseTrackingPage(
                user: user,
                formatAmount: formatAmount,
              ),
            ),
            CategoriesPage(user: user),
          ],
        ),
      ),
    );
  }
}

class _DashboardHomeTab extends StatelessWidget {
  const _DashboardHomeTab({
    required this.user,
    required this.recentTransactionsLimit,
    required this.formatAmount,
    required this.onOpenTransactions,
    required this.onOpenExpenseTracking,
    required this.onOpenMenu,
    required this.onConfirmDeleteTransaction,
  });

  final AppUser user;
  final int recentTransactionsLimit;
  final String Function(double amount) formatAmount;
  final VoidCallback onOpenTransactions;
  final VoidCallback onOpenExpenseTracking;
  final VoidCallback onOpenMenu;
  final Future<bool> Function(BuildContext, TransactionItem)
  onConfirmDeleteTransaction;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final colors = context.appColors;
          final recentTransactions = state.transactions
              .take(recentTransactionsLimit)
              .toList(growable: false);

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 164),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    appName: 'Coinly',
                    firstName: user.displayFirstName,
                    onOpenMenu: onOpenMenu,
                  ),
                  const SizedBox(height: 20),
                  _PeriodBalanceCard(
                    period: state.selectedPeriod,
                    label: state.selectedPeriodLabel,
                    amount: formatAmount(state.selectedPeriodBalance),
                    onPeriodChanged: context
                        .read<DashboardCubit>()
                        .changeTrackingPeriod,
                  ),
                  const SizedBox(height: 20),
                  _ExpenseTrackingShortcutCard(
                    label: 'Spent ${state.selectedPeriodLabel}',
                    amount: formatAmount(state.selectedPeriodExpense),
                    onTap: onOpenExpenseTracking,
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
                      if (state.transactions.length > recentTransactionsLimit)
                        OutlinedButton.icon(
                          onPressed: onOpenTransactions,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).brightness ==
                                    Brightness.dark
                                ? colors.accent
                                : colors.primary,
                            side: BorderSide(
                              color:
                                  Theme.of(context).brightness ==
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
                  if (state.transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No transactions yet. Add your first one.',
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTransactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                              onConfirmDeleteTransaction(context, transaction),
                          onDismissed: (_) {
                            context.read<DashboardCubit>().deleteTransaction(
                              transaction.id,
                            );
                            AppToast.show(
                              context,
                              message: '"${transaction.title}" deleted.',
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
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
                              leading: TransactionCategoryAvatar(
                                type: transaction.type,
                                categoryId: transaction.categoryId,
                                categoryLabel: transaction.categoryLabel,
                                categoryIconKey: transaction.categoryIconKey,
                              ),
                              title: Text(transaction.title),
                              subtitle: Text(
                                '${TransactionCategories.labelForTransaction(transaction)} - ${DateFormat.yMMMd().add_jm().format(transaction.createdAt)}',
                                style: TextStyle(color: colors.textSecondary),
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
                ],
              ),
            ),
          );
        },
      );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = const [
      (Icons.home_rounded, 'Home'),
      (Icons.receipt_long_rounded, 'Transactions'),
      (Icons.insights_rounded, 'Tracking'),
      (Icons.category_rounded, 'Categories'),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? colors.accent.withValues(alpha: 0.20)
                              : colors.primary.withValues(alpha: 0.12))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$1,
                        size: 20,
                        color: isSelected
                            ? (isDark ? colors.accent : colors.primary)
                            : colors.textSecondary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? colors.accent : colors.primary)
                              : colors.textSecondary,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomAddButton extends StatelessWidget {
  const _BottomAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [colors.accentDark, colors.accent]
              : [colors.primary, colors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isDark ? colors.accentDark : colors.primary).withValues(
              alpha: 0.30,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.appName,
    required this.firstName,
    required this.onOpenMenu,
  });

  final String appName;
  final String firstName;
  final VoidCallback onOpenMenu;

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
                  child: IconButton(
                    onPressed: onOpenMenu,
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Menu',
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
    required this.onOpenManageCategories,
  });

  final AppUser user;
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenAddTransaction;
  final VoidCallback onOpenManageCategories;

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
        child: SingleChildScrollView(
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
              const SizedBox(height: 12),
              _MenuActionTile(
                icon: Icons.category_outlined,
                title: 'Manage categories',
                subtitle: 'Add, edit, and delete custom categories',
                onTap: () {
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => onOpenManageCategories(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MenuActionTile(
                icon: Icons.logout_rounded,
                title: 'Log out',
                subtitle: 'Sign out from this account',
                onTap: () async {
                  Navigator.of(context).pop();
                  await onSignOut();
                },
              ),
              const SizedBox(height: 24),
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

class ExpenseTrackingPage extends StatelessWidget {
  const ExpenseTrackingPage({
    super.key,
    required this.user,
    required this.formatAmount,
  });

  final AppUser user;
  final String Function(double amount) formatAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopAppBar(title: 'Expense Tracking', showBackButton: false),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final previewTransactions = state.trackedExpenseTransactions
              .take(5)
              .toList(growable: false);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _ExpenseTrackingSection(
                selectedPeriod: state.selectedPeriod,
                onPeriodChanged: context
                    .read<DashboardCubit>()
                    .changeTrackingPeriod,
                amount: formatAmount(state.selectedPeriodExpense),
                label: 'Spent ${state.selectedPeriodLabel}',
                count: state.trackedExpenseTransactions.length,
                previewTransactions: previewTransactions,
                formatAmount: formatAmount,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeriodBalanceCard extends StatelessWidget {
  const _PeriodBalanceCard({
    required this.period,
    required this.label,
    required this.amount,
    required this.onPeriodChanged,
  });

  final DashboardTrackingPeriod period;
  final String label;
  final String amount;
  final ValueChanged<DashboardTrackingPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.primaryLight]),
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
          Text(
            'Balance for $label',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _PeriodToggle(
            selectedPeriod: period,
            onChanged: onPeriodChanged,
            selectedBackgroundColor: Colors.white,
            selectedForegroundColor: colors.primary,
            unselectedForegroundColor: Colors.white70,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            borderColor: Colors.white.withValues(alpha: 0.10),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTrackingShortcutCard extends StatelessWidget {
  const _ExpenseTrackingShortcutCard({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  final String label;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Tracking',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    amount,
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (isDark ? colors.accent : colors.primary).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.east_rounded,
                color: isDark ? colors.accent : colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTrackingSection extends StatelessWidget {
  const _ExpenseTrackingSection({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.amount,
    required this.label,
    required this.count,
    required this.previewTransactions,
    required this.formatAmount,
  });

  final DashboardTrackingPeriod selectedPeriod;
  final ValueChanged<DashboardTrackingPeriod> onPeriodChanged;
  final String amount;
  final String label;
  final int count;
  final List<TransactionItem> previewTransactions;
  final String Function(double amount) formatAmount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Tracking',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.insights_rounded, color: colors.error),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PeriodToggle(
            selectedPeriod: selectedPeriod,
            onChanged: onPeriodChanged,
            selectedBackgroundColor: isDark
                ? colors.accentDark
                : colors.primary,
            selectedForegroundColor: Colors.white,
            unselectedForegroundColor: colors.textSecondary,
            backgroundColor: isDark ? colors.primaryLight : colors.surfaceMuted,
            borderColor: isDark
                ? colors.accent.withValues(alpha: 0.18)
                : colors.border,
          ),
          const SizedBox(height: 18),
          Text(
            amount,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count == 0
                ? 'No expense transactions in this period yet.'
                : '$count expense transaction${count == 1 ? '' : 's'} recorded.',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          if (previewTransactions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Latest expenses in this period',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final transaction in previewTransactions) ...[
              _TrackedExpenseRow(
                transaction: transaction,
                amount: formatAmount(transaction.amount),
              ),
              if (transaction != previewTransactions.last)
                const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.selectedPeriod,
    required this.onChanged,
    required this.selectedBackgroundColor,
    required this.selectedForegroundColor,
    required this.unselectedForegroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final DashboardTrackingPeriod selectedPeriod;
  final ValueChanged<DashboardTrackingPeriod> onChanged;
  final Color selectedBackgroundColor;
  final Color selectedForegroundColor;
  final Color unselectedForegroundColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          for (final period in DashboardTrackingPeriod.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: period == selectedPeriod
                        ? selectedBackgroundColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    onTap: () => onChanged(period),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        switch (period) {
                          DashboardTrackingPeriod.daily => 'Daily',
                          DashboardTrackingPeriod.weekly => 'Weekly',
                          DashboardTrackingPeriod.monthly => 'Monthly',
                        },
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: period == selectedPeriod
                              ? selectedForegroundColor
                              : unselectedForegroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackedExpenseRow extends StatelessWidget {
  const _TrackedExpenseRow({required this.transaction, required this.amount});

  final TransactionItem transaction;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          TransactionCategoryAvatar(
            type: transaction.type,
            categoryId: transaction.categoryId,
            categoryIconKey: transaction.categoryIconKey,
            size: 40,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TransactionCategories.labelForTransaction(transaction)} - ${DateFormat.MMMd().add_jm().format(transaction.createdAt)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '-$amount',
            style: TextStyle(color: colors.error, fontWeight: FontWeight.w700),
          ),
        ],
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
  const _AddTransactionComposer({required this.userId});

  final String userId;

  @override
  State<_AddTransactionComposer> createState() =>
      _AddTransactionComposerState();
}

class _AddTransactionComposerState extends State<_AddTransactionComposer> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String _categoryId = TransactionCategories.defaultFor(
    TransactionType.expense,
  ).id;
  String _categoryLabel = TransactionCategories.defaultFor(
    TransactionType.expense,
  ).label;
  String _categoryIconKey = TransactionCategories.defaultFor(
    TransactionType.expense,
  ).iconKey;

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
        categoryId: _categoryId,
        categoryLabel: _categoryLabel,
        categoryIconKey: _categoryIconKey,
      ),
    );
  }

  void _changeType(TransactionType type) {
    _applySelectedCategory(TransactionCategories.defaultFor(type), type: type);
  }

  void _selectCategory(TransactionCategoryOption category) {
    _applySelectedCategory(category);
  }

  void _applySelectedCategory(
    TransactionCategoryOption category, {
    TransactionType? type,
  }) {
    setState(() {
      _type = type ?? category.type;
      _categoryId = category.id;
      _categoryLabel = category.label;
      _categoryIconKey = category.iconKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final colors = context.appColors;
    final viewInsets = mediaQuery.viewInsets.bottom;
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
                                    onTap: () =>
                                        _changeType(TransactionType.expense),
                                  ),
                                ),
                                Expanded(
                                  child: _TypeChoiceButton(
                                    label: 'Income',
                                    icon: Icons.arrow_downward_rounded,
                                    isSelected: _type == TransactionType.income,
                                    selectedColor: colors.accentDark,
                                    onTap: () =>
                                        _changeType(TransactionType.income),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Category',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _categoryLabel,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<List<TransactionCategoryOption>>(
                            stream: context
                                .read<CategoriesRepository>()
                                .watchCustomCategories(widget.userId),
                            builder: (context, snapshot) {
                              final customCategories =
                                  snapshot.data ??
                                  const <TransactionCategoryOption>[];
                              final categories =
                                  TransactionCategories.allForType(
                                    _type,
                                    customCategories: customCategories,
                                  );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    constraints: const BoxConstraints(
                                      maxHeight: 132,
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      10,
                                      10,
                                      8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          for (final category in categories)
                                            _CategoryChoiceChip(
                                              option: category,
                                              accent: accent,
                                              isSelected:
                                                  category.id == _categoryId,
                                              onTap: () =>
                                                  _selectCategory(category),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Manage custom categories from the side menu.',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _titleController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Title',
                              hintText: _type == TransactionType.income
                                  ? 'e.g. March salary, Client payment'
                                  : 'e.g. Uber ride, Electricity bill',
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
                                        ? '$_categoryLabel income entries increase your available balance.'
                                        : '$_categoryLabel expenses reduce your available balance.',
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

class _CategoryChoiceChip extends StatelessWidget {
  const _CategoryChoiceChip({
    required this.option,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final TransactionCategoryOption option;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? accent : colors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? accent : colors.border),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TransactionCategoryAvatar(
                type: option.type,
                categoryId: option.id,
                categoryLabel: option.label,
                categoryIconKey: option.iconKey,
                size: 24,
                iconSize: 12,
                foregroundColor: isSelected ? Colors.white : accent,
              ),
              const SizedBox(width: 8),
              Text(
                option.label,
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
    required this.categoryId,
    required this.categoryLabel,
    required this.categoryIconKey,
  });

  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryLabel;
  final String categoryIconKey;
}



