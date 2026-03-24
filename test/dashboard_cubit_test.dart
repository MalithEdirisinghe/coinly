import 'dart:async';

import 'package:coinly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:coinly/features/transactions/data/transactions_repository.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardCubit selected period summaries', () {
    late StreamController<List<TransactionItem>> controller;
    late _FakeTransactionsRepository repository;
    late DashboardCubit cubit;

    setUp(() {
      controller = StreamController<List<TransactionItem>>.broadcast();
      repository = _FakeTransactionsRepository(controller.stream);
      cubit = DashboardCubit(
        transactionsRepository: repository,
        userId: 'user-1',
        now: () => DateTime(2026, 3, 24, 10),
      );
    });

    tearDown(() async {
      await cubit.close();
      await controller.close();
    });

    test(
      'computes monthly, weekly, and daily selected period values',
      () async {
        cubit.start();
        controller.add([
          TransactionItem(
            id: '1',
            title: 'Salary',
            amount: 500,
            type: TransactionType.income,
            createdAt: DateTime(2026, 3, 24, 8),
          ),
          TransactionItem(
            id: '2',
            title: 'Lunch',
            amount: 50,
            type: TransactionType.expense,
            createdAt: DateTime(2026, 3, 24, 9),
          ),
          TransactionItem(
            id: '3',
            title: 'Taxi',
            amount: 30,
            type: TransactionType.expense,
            createdAt: DateTime(2026, 3, 23, 18),
          ),
          TransactionItem(
            id: '4',
            title: 'Bills',
            amount: 40,
            type: TransactionType.expense,
            createdAt: DateTime(2026, 3, 5, 12),
          ),
          TransactionItem(
            id: '5',
            title: 'Old',
            amount: 25,
            type: TransactionType.expense,
            createdAt: DateTime(2026, 2, 27, 12),
          ),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.selectedPeriod, DashboardTrackingPeriod.monthly);
        expect(cubit.state.selectedPeriodIncome, 500);
        expect(cubit.state.selectedPeriodExpense, 120);
        expect(cubit.state.selectedPeriodBalance, 380);
        expect(cubit.state.selectedPeriodLabel, 'this month');

        cubit.changeTrackingPeriod(DashboardTrackingPeriod.weekly);
        expect(cubit.state.selectedPeriodExpense, 80);
        expect(cubit.state.selectedPeriodBalance, 420);
        expect(cubit.state.trackedExpenseTransactions.length, 2);

        cubit.changeTrackingPeriod(DashboardTrackingPeriod.daily);
        expect(cubit.state.selectedPeriodExpense, 50);
        expect(cubit.state.selectedPeriodBalance, 450);
        expect(cubit.state.trackedExpenseTransactions.length, 1);
      },
    );
  });
}

class _FakeTransactionsRepository implements TransactionsRepository {
  _FakeTransactionsRepository(this._stream);

  final Stream<List<TransactionItem>> _stream;

  @override
  Stream<List<TransactionItem>> watchTransactions(String userId) => _stream;

  @override
  Future<void> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String categoryLabel,
    required String categoryIconKey,
  }) async {}

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {}

  @override
  Future<TransactionsPageResult> fetchTransactionsPage({
    required String userId,
    int limit = 20,
    startAfter,
  }) {
    throw UnimplementedError();
  }

  @override
  void cacheTransactionsPage({
    required String userId,
    required List<TransactionItem> transactions,
    required lastDocument,
    required bool hasMore,
  }) {}

  @override
  CachedTransactionsPage? getCachedTransactionsPage(String userId) => null;

  @override
  bool hasFreshTransactionsCache(
    String userId, {
    Duration maxAge = TransactionsRepository.transactionsCacheDuration,
  }) => false;

  @override
  void invalidateTransactionsCache(String userId) {}
}
