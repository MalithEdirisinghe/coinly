import 'package:coinly/app/theme/app_colors.dart';
import 'package:coinly/core/utils/currency_formatter.dart';
import 'package:coinly/core/widgets/app_top_app_bar.dart';
import 'package:coinly/core/widgets/app_confirm_dialog.dart';
import 'package:coinly/core/widgets/app_toast.dart';
import 'package:coinly/core/widgets/transaction_category_avatar.dart';
import 'package:coinly/core/constants/transaction_categories.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:coinly/features/transactions/data/transactions_repository.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:coinly/features/transactions/presentation/cubit/transactions_page_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionsPageCubit(
        transactionsRepository: context.read<TransactionsRepository>(),
        userId: user.id,
      )..loadInitial(),
      child: _TransactionsView(user: user),
    );
  }
}

class _TransactionsView extends StatefulWidget {
  const _TransactionsView({required this.user});

  final AppUser user;

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  late final ScrollController _scrollController;

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(
      amount,
      currencyCode: widget.user.currencyCode,
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<TransactionsPageCubit>().loadMore();
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<TransactionsPageCubit, TransactionsPageState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        AppToast.show(
          context,
          message: state.errorMessage!,
          type: AppToastType.error,
        );
        context.read<TransactionsPageCubit>().clearError();
      },
      child: Scaffold(
        appBar: const AppTopAppBar(title: 'All Transactions'),
        body: BlocBuilder<TransactionsPageCubit, TransactionsPageState>(
          builder: (context, state) {
            if (state.isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.transactions.isEmpty) {
              return RefreshIndicator(
                color: Theme.of(context).brightness == Brightness.dark
                    ? colors.accent
                    : colors.primary,
                backgroundColor: colors.surface,
                onRefresh: () =>
                    context.read<TransactionsPageCubit>().refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
                  children: [
                    Center(
                      child: Text(
                        'No transactions available yet.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }

            final itemCount =
                state.transactions.length +
                (state.isLoadingMore || state.hasMore ? 1 : 0);

            return RefreshIndicator(
              color: Theme.of(context).brightness == Brightness.dark
                  ? colors.accent
                  : colors.primary,
              backgroundColor: colors.surface,
              onRefresh: () => context.read<TransactionsPageCubit>().refresh(),
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: itemCount,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= state.transactions.length) {
                    if (state.isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Center(
                      child: Text(
                        state.hasMore
                            ? 'Scroll to load more'
                            : 'You are all caught up.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    );
                  }

                  final transaction = state.transactions[index];
                  final amountColor = transaction.type == TransactionType.income
                      ? colors.accentDark
                      : colors.error;

                  return Dismissible(
                    key: ValueKey('transactions-page-${transaction.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) =>
                        _confirmDeleteTransaction(context, transaction),
                    onDismissed: (_) {
                      context.read<TransactionsPageCubit>().deleteTransaction(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
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
                          '${transaction.type == TransactionType.income ? '+' : '-'}${_formatAmount(transaction.amount)}',
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
            );
          },
        ),
      ),
    );
  }
}
