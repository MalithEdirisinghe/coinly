import 'package:coinly/app/theme/app_colors.dart';
import 'package:coinly/core/utils/currency_formatter.dart';
import 'package:coinly/core/widgets/app_top_app_bar.dart';
import 'package:coinly/core/widgets/app_toast.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:coinly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key, required this.user});

  final AppUser user;

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount, currencyCode: user.currencyCode);
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: const AppTopAppBar(title: 'All Transactions'),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.transactions.isEmpty) {
            return Center(
              child: Text(
                'No transactions available yet.',
                style: TextStyle(color: colors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: state.transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.white),
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
                    title: Text(transaction.title),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(transaction.createdAt),
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
          );
        },
      ),
    );
  }
}
