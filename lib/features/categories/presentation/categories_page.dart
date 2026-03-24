import 'package:coinly/app/theme/app_colors.dart';
import 'package:coinly/core/constants/transaction_categories.dart';
import 'package:coinly/core/widgets/app_toast.dart';
import 'package:coinly/core/widgets/app_top_app_bar.dart';
import 'package:coinly/core/widgets/app_confirm_dialog.dart';
import 'package:coinly/core/widgets/transaction_category_avatar.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:coinly/features/categories/data/categories_repository.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key, required this.user});

  final AppUser user;

  Future<void> _openCategoryEditor(
    BuildContext context, {
    TransactionCategoryOption? category,
  }) async {
    final repository = context.read<CategoriesRepository>();
    final result = await showDialog<_CategoryEditorResult>(
      context: context,
      builder: (_) => _CategoryEditorDialog(category: category),
    );

    if (result == null || !context.mounted) {
      return;
    }

    try {
      if (category == null) {
        await repository.addCategory(
          userId: user.id,
          name: result.name,
          type: result.type,
          iconKey: result.iconKey,
        );
        if (context.mounted) {
          AppToast.show(
            context,
            message: 'Custom category added.',
            type: AppToastType.success,
          );
        }
      } else {
        await repository.updateCategory(
          userId: user.id,
          categoryId: category.id,
          name: result.name,
          type: result.type,
          iconKey: result.iconKey,
        );
        if (context.mounted) {
          AppToast.show(
            context,
            message: 'Category updated.',
            type: AppToastType.success,
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.show(
          context,
          message: 'Could not save the category.',
          type: AppToastType.error,
        );
      }
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    TransactionCategoryOption category,
  ) async {
    final shouldDelete = await AppConfirmDialog.show(
      context,
      title: 'Delete category?',
      message: 'Delete "${category.label}" from your custom categories?',
    );

    if (!shouldDelete || !context.mounted) {
      return;
    }

    try {
      await context.read<CategoriesRepository>().deleteCategory(
        userId: user.id,
        categoryId: category.id,
      );
      if (context.mounted) {
        AppToast.show(
          context,
          message: 'Category deleted.',
          type: AppToastType.success,
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.show(
          context,
          message: 'Could not delete the category.',
          type: AppToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CategoriesRepository>();

    return Scaffold(
      appBar: const AppTopAppBar(title: 'Manage Categories'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
      body: StreamBuilder<List<TransactionCategoryOption>>(
        stream: repository.watchCustomCategories(user.id),
        builder: (context, snapshot) {
          final customCategories =
              snapshot.data ?? const <TransactionCategoryOption>[];
          final expenseCustom = customCategories
              .where((item) => item.type == TransactionType.expense)
              .toList(growable: false);
          final incomeCustom = customCategories
              .where((item) => item.type == TransactionType.income)
              .toList(growable: false);

          if (snapshot.connectionState == ConnectionState.waiting &&
              customCategories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _CategorySection(
                title: 'Expense categories',
                description:
                    'Built-in categories stay fixed. Custom ones can be edited or deleted.',
                builtInCategories: TransactionCategories.expense,
                customCategories: expenseCustom,
                onEdit: (category) =>
                    _openCategoryEditor(context, category: category),
                onDelete: (category) => _deleteCategory(context, category),
              ),
              const SizedBox(height: 20),
              _CategorySection(
                title: 'Income categories',
                description:
                    'Use custom categories when your income sources need more detail.',
                builtInCategories: TransactionCategories.income,
                customCategories: incomeCustom,
                onEdit: (category) =>
                    _openCategoryEditor(context, category: category),
                onDelete: (category) => _deleteCategory(context, category),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.description,
    required this.builtInCategories,
    required this.customCategories,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String description;
  final List<TransactionCategoryOption> builtInCategories;
  final List<TransactionCategoryOption> customCategories;
  final ValueChanged<TransactionCategoryOption> onEdit;
  final ValueChanged<TransactionCategoryOption> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 18),
          Text(
            'Built-in',
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final category in builtInCategories)
                Chip(
                  avatar: Icon(
                    category.icon,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  label: Text(category.label),
                  side: BorderSide(color: colors.border),
                  backgroundColor: colors.surfaceMuted,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Custom',
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (customCategories.isEmpty)
            Text(
              'No custom categories yet.',
              style: TextStyle(color: colors.textSecondary),
            )
          else
            Column(
              children: [
                for (final category in customCategories) ...[
                  _CustomCategoryTile(
                    category: category,
                    onEdit: () => onEdit(category),
                    onDelete: () => onDelete(category),
                  ),
                  if (category != customCategories.last)
                    const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CustomCategoryTile extends StatelessWidget {
  const _CustomCategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionCategoryOption category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          TransactionCategoryAvatar(
            type: category.type,
            categoryId: category.id,
            categoryLabel: category.label,
            categoryIconKey: category.iconKey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.type == TransactionType.income
                      ? 'Custom income category'
                      : 'Custom expense category',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline_rounded, color: colors.error),
          ),
        ],
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.category});

  final TransactionCategoryOption? category;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late TransactionType _type;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.label ?? '');
    _type = widget.category?.type ?? TransactionType.expense;
    _iconKey =
        widget.category?.iconKey ??
        TransactionCategories.customIconOptions.first.key;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _CategoryEditorResult(
        name: _nameController.text.trim(),
        type: _type,
        iconKey: _iconKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEditing = widget.category != null;
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets.bottom;
    final previewCategory = TransactionCategories.custom(
      id: 'preview',
      label: _nameController.text.trim().isEmpty
          ? 'Preview'
          : _nameController.text.trim(),
      type: _type,
      iconKey: _iconKey,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          maxHeight: (mediaQuery.size.height - viewInsets - 48).clamp(
            360.0,
            mediaQuery.size.height,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit category' : 'New category',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create custom categories for the way you track money.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      hintText: 'e.g. Subscriptions, Side hustle',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Category name is required.';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Type',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _EditorTypeButton(
                          label: 'Expense',
                          isSelected: _type == TransactionType.expense,
                          accent: colors.error,
                          onTap: () =>
                              setState(() => _type = TransactionType.expense),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EditorTypeButton(
                          label: 'Income',
                          isSelected: _type == TransactionType.income,
                          accent: colors.accentDark,
                          onTap: () =>
                              setState(() => _type = TransactionType.income),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Icon',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option
                          in TransactionCategories.customIconOptions)
                        _IconChoiceChip(
                          option: option,
                          isSelected: option.key == _iconKey,
                          onTap: () => setState(() => _iconKey = option.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        TransactionCategoryAvatar(
                          type: previewCategory.type,
                          categoryId: previewCategory.id,
                          categoryLabel: previewCategory.label,
                          categoryIconKey: previewCategory.iconKey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            previewCategory.label,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          child: Text(isEditing ? 'Update' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorTypeButton extends StatelessWidget {
  const _EditorTypeButton({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accent : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? accent : colors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _IconChoiceChip extends StatelessWidget {
  const _IconChoiceChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final TransactionCategoryIconOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 18,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              option.label,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEditorResult {
  const _CategoryEditorResult({
    required this.name,
    required this.type,
    required this.iconKey,
  });

  final String name;
  final TransactionType type;
  final String iconKey;
}
