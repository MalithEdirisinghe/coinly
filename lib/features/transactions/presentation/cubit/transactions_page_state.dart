part of 'transactions_page_cubit.dart';

class TransactionsPageState extends Equatable {
  const TransactionsPageState({
    this.transactions = const [],
    this.isInitialLoading = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDocument,
    this.errorMessage,
  });

  final List<TransactionItem> transactions;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final String? errorMessage;

  TransactionsPageState copyWith({
    List<TransactionItem>? transactions,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    String? errorMessage,
    bool clearError = false,
    bool resetCursor = false,
  }) {
    return TransactionsPageState(
      transactions: transactions ?? this.transactions,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: resetCursor ? null : lastDocument ?? this.lastDocument,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    hasMore,
    lastDocument,
    errorMessage,
  ];
}
