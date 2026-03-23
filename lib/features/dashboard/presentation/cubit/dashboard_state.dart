part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.balance = 0,
    this.income = 0,
    this.expense = 0,
    this.isLoading = true,
    this.transactions = const [],
    this.errorMessage,
  });

  final double balance;
  final double income;
  final double expense;
  final bool isLoading;
  final List<TransactionItem> transactions;
  final String? errorMessage;

  DashboardState copyWith({
    double? balance,
    double? income,
    double? expense,
    bool? isLoading,
    List<TransactionItem>? transactions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      balance: balance ?? this.balance,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    balance,
    income,
    expense,
    isLoading,
    transactions,
    errorMessage,
  ];
}
