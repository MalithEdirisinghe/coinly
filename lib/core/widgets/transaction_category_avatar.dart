import 'package:coinly/app/theme/app_colors.dart';
import 'package:coinly/core/constants/transaction_categories.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:flutter/material.dart';

class TransactionCategoryAvatar extends StatelessWidget {
  const TransactionCategoryAvatar({
    super.key,
    required this.type,
    required this.categoryId,
    this.categoryLabel,
    this.categoryIconKey,
    this.foregroundColor,
    this.size = 42,
    this.iconSize = 20,
  });

  final TransactionType type;
  final String? categoryId;
  final String? categoryLabel;
  final String? categoryIconKey;
  final Color? foregroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final category = categoryIconKey != null && categoryIconKey!.isNotEmpty
        ? TransactionCategoryOption(
            id: categoryId ?? '',
            type: type,
            label: '',
            icon: TransactionCategories.iconForKey(categoryIconKey),
            iconKey: categoryIconKey!,
          )
        : TransactionCategories.resolve(type: type, categoryId: categoryId);
    final accent = type == TransactionType.income
        ? colors.accentDark
        : colors.error;
    final iconColor = foregroundColor ?? accent;

    final fallbackLetter = _fallbackLetter(categoryLabel);
    final showLetterFallback =
        fallbackLetter != null &&
        categoryIconKey == 'other' &&
        categoryLabel != null &&
        categoryLabel!.trim().toLowerCase() != 'other';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Center(
        child: showLetterFallback
            ? Text(
                fallbackLetter,
                style: TextStyle(
                  color: iconColor,
                  fontSize: iconSize,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Icon(category.icon, color: iconColor, size: iconSize),
      ),
    );
  }

  String? _fallbackLetter(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed.substring(0, 1).toUpperCase();
  }
}
