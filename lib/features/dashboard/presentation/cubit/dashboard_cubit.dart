import 'dart:async';

import 'package:coinly/features/transactions/data/transactions_repository.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required TransactionsRepository transactionsRepository,
    required String userId,
  }) : _transactionsRepository = transactionsRepository,
       _userId = userId,
       super(const DashboardState());

  final TransactionsRepository _transactionsRepository;
  final String _userId;
  StreamSubscription<List<TransactionItem>>? _subscription;

  void start() {
    emit(state.copyWith(isLoading: true, clearError: true));
    _subscription?.cancel();
    _subscription = _transactionsRepository
        .watchTransactions(_userId)
        .listen(
          (transactions) {
            final income = transactions
                .where((item) => item.type == TransactionType.income)
                .fold<double>(0, (total, item) => total + item.amount);
            final expense = transactions
                .where((item) => item.type == TransactionType.expense)
                .fold<double>(0, (total, item) => total + item.amount);

            emit(
              state.copyWith(
                isLoading: false,
                transactions: transactions,
                income: income,
                expense: expense,
                balance: income - expense,
                clearError: true,
              ),
            );
          },
          onError: (_) {
            emit(
              state.copyWith(
                isLoading: false,
                errorMessage: 'Failed to load transactions from Firestore.',
              ),
            );
          },
        );
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
  }) async {
    try {
      await _transactionsRepository.addTransaction(
        userId: _userId,
        title: title,
        amount: amount,
        type: type,
      );
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Could not save the transaction.'));
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
