import 'package:coinly/core/constants/transaction_categories.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionCategories', () {
    test('falls back to default expense category for unknown ids', () {
      final category = TransactionCategories.resolve(
        type: TransactionType.expense,
        categoryId: 'missing',
      );

      expect(category.id, 'other_expense');
    });

    test('falls back to default income category for missing ids', () {
      final category = TransactionCategories.resolve(
        type: TransactionType.income,
        categoryId: '',
      );

      expect(category.id, 'other_income');
    });
  });
}
