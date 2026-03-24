import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coinly/features/transactions/data/transactions_repository.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_state.dart';

enum DashboardTrackingPeriod { daily, weekly, monthly }

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required TransactionsRepository transactionsRepository,
    required String userId,
    DateTime Function()? now,
  }) : _transactionsRepository = transactionsRepository,
       _userId = userId,
       _now = now ?? DateTime.now,
       super(const DashboardState());

  final TransactionsRepository _transactionsRepository;
  final String _userId;
  final DateTime Function() _now;
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
            final summary = _buildTrackingSummary(
              transactions: transactions,
              period: state.selectedPeriod,
            );

            emit(
              state.copyWith(
                isLoading: false,
                transactions: transactions,
                income: income,
                expense: expense,
                balance: income - expense,
                selectedPeriod: state.selectedPeriod,
                selectedPeriodIncome: summary.income,
                selectedPeriodExpense: summary.expense,
                selectedPeriodBalance: summary.balance,
                selectedPeriodLabel: summary.label,
                trackedExpenseTransactions: summary.expenseTransactions,
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

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _transactionsRepository.deleteTransaction(
        userId: _userId,
        transactionId: transactionId,
      );
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage: _mapFirestoreError(
            error,
            fallback: 'Could not delete the transaction.',
          ),
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void changeTrackingPeriod(DashboardTrackingPeriod period) {
    final summary = _buildTrackingSummary(
      transactions: state.transactions,
      period: period,
    );

    emit(
      state.copyWith(
        selectedPeriod: period,
        selectedPeriodIncome: summary.income,
        selectedPeriodExpense: summary.expense,
        selectedPeriodBalance: summary.balance,
        selectedPeriodLabel: summary.label,
        trackedExpenseTransactions: summary.expenseTransactions,
        clearError: true,
      ),
    );
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

  _TrackingSummary _buildTrackingSummary({
    required List<TransactionItem> transactions,
    required DashboardTrackingPeriod period,
  }) {
    final start = _startOfPeriod(period, _now());
    final end = _endOfPeriod(period, start);

    final inRange = transactions
        .where(
          (item) =>
              !item.createdAt.isBefore(start) && item.createdAt.isBefore(end),
        )
        .toList(growable: false);

    final income = inRange
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (total, item) => total + item.amount);
    final expense = inRange
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (total, item) => total + item.amount);
    final expenseTransactions = inRange
        .where((item) => item.type == TransactionType.expense)
        .toList(growable: false);

    return _TrackingSummary(
      income: income,
      expense: expense,
      balance: income - expense,
      label: switch (period) {
        DashboardTrackingPeriod.daily => 'today',
        DashboardTrackingPeriod.weekly => 'this week',
        DashboardTrackingPeriod.monthly => 'this month',
      },
      expenseTransactions: expenseTransactions,
    );
  }

  DateTime _startOfPeriod(DashboardTrackingPeriod period, DateTime now) {
    final date = DateTime(now.year, now.month, now.day);
    switch (period) {
      case DashboardTrackingPeriod.daily:
        return date;
      case DashboardTrackingPeriod.weekly:
        return date.subtract(Duration(days: date.weekday - 1));
      case DashboardTrackingPeriod.monthly:
        return DateTime(date.year, date.month);
    }
  }

  DateTime _endOfPeriod(DashboardTrackingPeriod period, DateTime start) {
    switch (period) {
      case DashboardTrackingPeriod.daily:
        return start.add(const Duration(days: 1));
      case DashboardTrackingPeriod.weekly:
        return start.add(const Duration(days: 7));
      case DashboardTrackingPeriod.monthly:
        return DateTime(start.year, start.month + 1);
    }
  }
}

class _TrackingSummary {
  const _TrackingSummary({
    required this.income,
    required this.expense,
    required this.balance,
    required this.label,
    required this.expenseTransactions,
  });

  final double income;
  final double expense;
  final double balance;
  final String label;
  final List<TransactionItem> expenseTransactions;
}
