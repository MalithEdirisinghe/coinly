import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:flutter/material.dart';

class TransactionCategoryIconOption {
  const TransactionCategoryIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

class TransactionCategoryOption {
  const TransactionCategoryOption({
    required this.id,
    required this.type,
    required this.label,
    required this.icon,
    required this.iconKey,
    this.isCustom = false,
  });

  final String id;
  final TransactionType type;
  final String label;
  final IconData icon;
  final String iconKey;
  final bool isCustom;
}

abstract final class TransactionCategories {
  static const customIconOptions = [
    TransactionCategoryIconOption(
      key: 'groceries',
      label: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'transport',
      label: 'Transport',
      icon: Icons.directions_car_filled_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'dining',
      label: 'Dining',
      icon: Icons.restaurant_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'bills',
      label: 'Bills',
      icon: Icons.receipt_long_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'shopping',
      label: 'Shopping',
      icon: Icons.shopping_bag_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'health',
      label: 'Health',
      icon: Icons.favorite_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'salary',
      label: 'Salary',
      icon: Icons.payments_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'work',
      label: 'Work',
      icon: Icons.work_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'business',
      label: 'Business',
      icon: Icons.storefront_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'gift',
      label: 'Gift',
      icon: Icons.card_giftcard_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'refund',
      label: 'Refund',
      icon: Icons.replay_circle_filled_rounded,
    ),
    TransactionCategoryIconOption(
      key: 'other',
      label: 'Other',
      icon: Icons.category_rounded,
    ),
  ];

  static const expense = [
    TransactionCategoryOption(
      id: 'groceries',
      type: TransactionType.expense,
      label: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      iconKey: 'groceries',
    ),
    TransactionCategoryOption(
      id: 'transport',
      type: TransactionType.expense,
      label: 'Transport',
      icon: Icons.directions_car_filled_rounded,
      iconKey: 'transport',
    ),
    TransactionCategoryOption(
      id: 'dining',
      type: TransactionType.expense,
      label: 'Dining',
      icon: Icons.restaurant_rounded,
      iconKey: 'dining',
    ),
    TransactionCategoryOption(
      id: 'bills',
      type: TransactionType.expense,
      label: 'Bills',
      icon: Icons.receipt_long_rounded,
      iconKey: 'bills',
    ),
    TransactionCategoryOption(
      id: 'shopping',
      type: TransactionType.expense,
      label: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      iconKey: 'shopping',
    ),
    TransactionCategoryOption(
      id: 'health',
      type: TransactionType.expense,
      label: 'Health',
      icon: Icons.favorite_rounded,
      iconKey: 'health',
    ),
    TransactionCategoryOption(
      id: 'other_expense',
      type: TransactionType.expense,
      label: 'Other',
      icon: Icons.category_rounded,
      iconKey: 'other',
    ),
  ];

  static const income = [
    TransactionCategoryOption(
      id: 'salary',
      type: TransactionType.income,
      label: 'Salary',
      icon: Icons.payments_rounded,
      iconKey: 'salary',
    ),
    TransactionCategoryOption(
      id: 'freelance',
      type: TransactionType.income,
      label: 'Freelance',
      icon: Icons.work_rounded,
      iconKey: 'work',
    ),
    TransactionCategoryOption(
      id: 'business',
      type: TransactionType.income,
      label: 'Business',
      icon: Icons.storefront_rounded,
      iconKey: 'business',
    ),
    TransactionCategoryOption(
      id: 'gift',
      type: TransactionType.income,
      label: 'Gift',
      icon: Icons.card_giftcard_rounded,
      iconKey: 'gift',
    ),
    TransactionCategoryOption(
      id: 'refund',
      type: TransactionType.income,
      label: 'Refund',
      icon: Icons.replay_circle_filled_rounded,
      iconKey: 'refund',
    ),
    TransactionCategoryOption(
      id: 'other_income',
      type: TransactionType.income,
      label: 'Other',
      icon: Icons.category_rounded,
      iconKey: 'other',
    ),
  ];

  static List<TransactionCategoryOption> forType(TransactionType type) {
    return type == TransactionType.income ? income : expense;
  }

  static List<TransactionCategoryOption> allForType(
    TransactionType type, {
    List<TransactionCategoryOption> customCategories = const [],
  }) {
    final filteredCustom = customCategories
        .where((category) => category.type == type)
        .toList(growable: false);

    return [...forType(type), ...filteredCustom];
  }

  static TransactionCategoryOption defaultFor(TransactionType type) {
    return forType(type).last;
  }

  static TransactionCategoryOption resolve({
    required TransactionType type,
    String? categoryId,
    List<TransactionCategoryOption> additionalCategories = const [],
  }) {
    final categories = allForType(type, customCategories: additionalCategories);
    return categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => defaultFor(type),
    );
  }

  static TransactionCategoryOption custom({
    required String id,
    required String label,
    required TransactionType type,
    required String iconKey,
  }) {
    return TransactionCategoryOption(
      id: id,
      type: type,
      label: label,
      icon: iconForKey(iconKey),
      iconKey: iconKey,
      isCustom: true,
    );
  }

  static IconData iconForKey(String? iconKey) {
    for (final option in customIconOptions) {
      if (option.key == iconKey) {
        return option.icon;
      }
    }

    return Icons.category_rounded;
  }

  static TransactionCategoryOption optionForTransaction(TransactionItem item) {
    if (item.categoryLabel.isNotEmpty || item.categoryIconKey.isNotEmpty) {
      return TransactionCategoryOption(
        id: item.categoryId,
        type: item.type,
        label: item.categoryLabel.isNotEmpty
            ? item.categoryLabel
            : resolve(type: item.type, categoryId: item.categoryId).label,
        icon: item.categoryIconKey.isNotEmpty
            ? iconForKey(item.categoryIconKey)
            : resolve(type: item.type, categoryId: item.categoryId).icon,
        iconKey: item.categoryIconKey.isNotEmpty
            ? item.categoryIconKey
            : resolve(type: item.type, categoryId: item.categoryId).iconKey,
      );
    }

    return resolve(type: item.type, categoryId: item.categoryId);
  }

  static String labelForTransaction(TransactionItem item) {
    return optionForTransaction(item).label;
  }
}
