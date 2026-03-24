import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coinly/features/transactions/data/transactions_repository.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'transactions_page_state.dart';

class TransactionsPageCubit extends Cubit<TransactionsPageState> {
  TransactionsPageCubit({
    required TransactionsRepository transactionsRepository,
    required String userId,
  }) : _transactionsRepository = transactionsRepository,
       _userId = userId,
       super(const TransactionsPageState());

  static const int _pageSize = 20;

  final TransactionsRepository _transactionsRepository;
  final String _userId;

  Future<void> loadInitial() async {
    final cached = _transactionsRepository.getCachedTransactionsPage(_userId);
    if (cached != null) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          transactions: cached.transactions,
          lastDocument: cached.lastDocument,
          hasMore: cached.hasMore,
          clearError: true,
        ),
      );

      if (_transactionsRepository.hasFreshTransactionsCache(_userId)) {
        return;
      }

      await refresh(showLoader: false);
      return;
    }

    emit(
      state.copyWith(
        isInitialLoading: true,
        isRefreshing: false,
        errorMessage: null,
        transactions: const [],
        hasMore: true,
        clearError: true,
        resetCursor: true,
      ),
    );

    try {
      final result = await _transactionsRepository.fetchTransactionsPage(
        userId: _userId,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          transactions: result.transactions,
          lastDocument: result.lastDocument,
          hasMore: result.hasMore,
          clearError: true,
        ),
      );
      _transactionsRepository.cacheTransactionsPage(
        userId: _userId,
        transactions: result.transactions,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
      );
    } catch (error) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          errorMessage: _mapError(
            error,
            fallback: 'Could not load transactions.',
          ),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.lastDocument == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final result = await _transactionsRepository.fetchTransactionsPage(
        userId: _userId,
        limit: _pageSize,
        startAfter: state.lastDocument,
      );
      emit(
        state.copyWith(
          isLoadingMore: false,
          transactions: [...state.transactions, ...result.transactions],
          lastDocument: result.lastDocument ?? state.lastDocument,
          hasMore: result.hasMore,
          clearError: true,
        ),
      );
      _transactionsRepository.cacheTransactionsPage(
        userId: _userId,
        transactions: [...state.transactions, ...result.transactions],
        lastDocument: result.lastDocument ?? state.lastDocument,
        hasMore: result.hasMore,
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: _mapError(
            error,
            fallback: 'Could not load more transactions.',
          ),
        ),
      );
    }
  }

  Future<void> refresh({bool showLoader = true}) async {
    if (state.isInitialLoading || state.isLoadingMore || state.isRefreshing) {
      return;
    }

    emit(
      state.copyWith(
        isRefreshing: true,
        isInitialLoading: showLoader && state.transactions.isEmpty,
        clearError: true,
      ),
    );

    try {
      final result = await _transactionsRepository.fetchTransactionsPage(
        userId: _userId,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          transactions: result.transactions,
          lastDocument: result.lastDocument,
          hasMore: result.hasMore,
          clearError: true,
        ),
      );
      _transactionsRepository.cacheTransactionsPage(
        userId: _userId,
        transactions: result.transactions,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
      );
    } catch (error) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          errorMessage: _mapError(
            error,
            fallback: 'Could not refresh transactions.',
          ),
        ),
      );
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final previousTransactions = state.transactions;
    emit(
      state.copyWith(
        transactions: previousTransactions
            .where((item) => item.id != transactionId)
            .toList(growable: false),
        clearError: true,
      ),
    );

    try {
      await _transactionsRepository.deleteTransaction(
        userId: _userId,
        transactionId: transactionId,
      );
      _transactionsRepository.cacheTransactionsPage(
        userId: _userId,
        transactions: state.transactions,
        lastDocument: state.lastDocument,
        hasMore: state.hasMore,
      );
    } catch (error) {
      emit(
        state.copyWith(
          transactions: previousTransactions,
          errorMessage: _mapError(
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

  String _mapError(Object error, {required String fallback}) {
    if (error is FirebaseException) {
      return error.message ?? fallback;
    }

    return fallback;
  }
}
