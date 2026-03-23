import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
        onError: (error) {
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: _mapFirestoreError(
                error,
                fallback: 'Failed to load transactions from Firestore.',
              ),
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
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage: _mapFirestoreError(
            error,
            fallback: 'Could not save the transaction.',
          ),
        ),
      );
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

  String _mapFirestoreError(Object error, {required String fallback}) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore rules blocked this action. Check your database rules.';
        case 'unavailable':
          return 'Firestore is unavailable right now. Check your internet connection.';
        case 'not-found':
          return 'Firestore database was not found for this project.';
        case 'failed-precondition':
          return error.message ?? 'Firestore is not fully configured yet.';
        default:
          return error.message ?? fallback;
      }
    }

    return fallback;
  }
}
