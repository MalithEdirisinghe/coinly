part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.balance = 0,
    this.income = 0,
    this.expense = 0,
    this.isLoading = true,
    this.transactions = const [],
    this.selectedPeriod = DashboardTrackingPeriod.monthly,
    this.selectedPeriodIncome = 0,
    this.selectedPeriodExpense = 0,
    this.selectedPeriodBalance = 0,
    this.selectedPeriodLabel = 'this month',
    this.trackedExpenseTransactions = const [],
    this.errorMessage,
  });

  final double balance;
  final double income;
  final double expense;
  final bool isLoading;
  final List<TransactionItem> transactions;
  final DashboardTrackingPeriod selectedPeriod;
  final double selectedPeriodIncome;
  final double selectedPeriodExpense;
  final double selectedPeriodBalance;
  final String selectedPeriodLabel;
  final List<TransactionItem> trackedExpenseTransactions;
  final String? errorMessage;

  DashboardState copyWith({
    double? balance,
    double? income,
    double? expense,
    bool? isLoading,
    List<TransactionItem>? transactions,
    DashboardTrackingPeriod? selectedPeriod,
    double? selectedPeriodIncome,
    double? selectedPeriodExpense,
    double? selectedPeriodBalance,
    String? selectedPeriodLabel,
    List<TransactionItem>? trackedExpenseTransactions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      balance: balance ?? this.balance,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedPeriodIncome: selectedPeriodIncome ?? this.selectedPeriodIncome,
      selectedPeriodExpense:
          selectedPeriodExpense ?? this.selectedPeriodExpense,
      selectedPeriodBalance:
          selectedPeriodBalance ?? this.selectedPeriodBalance,
      selectedPeriodLabel: selectedPeriodLabel ?? this.selectedPeriodLabel,
      trackedExpenseTransactions:
          trackedExpenseTransactions ?? this.trackedExpenseTransactions,
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
    selectedPeriod,
    selectedPeriodIncome,
    selectedPeriodExpense,
    selectedPeriodBalance,
    selectedPeriodLabel,
    trackedExpenseTransactions,
    errorMessage,
  ];
}
