import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';
import 'category_chip.dart';

/// Reusable Category Selector that dynamically renders Income/Expense categories loaded from SQLite.
class CategorySelector extends StatelessWidget {
  final TransactionType transactionType;
  final ExpenseCategory selectedCategory;
  final ValueChanged<ExpenseCategory> onCategoryChanged;

  const CategorySelector({
    super.key,
    required this.transactionType,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ExpenseProvider>(context);

    // Dynamic categories from SQLite database via Provider
    final dynamicCategories = transactionType == TransactionType.income
        ? provider.incomeCategories
        : provider.expenseCategories;

    // Fallback if database is loading or empty
    final categories = dynamicCategories.isNotEmpty
        ? dynamicCategories
        : (transactionType == TransactionType.income
            ? ExpenseCategory.incomeCategories
            : ExpenseCategory.expenseCategories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selectedCategory.color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedCategory.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selectedCategory.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: categories.map((cat) {
            final isSelected = selectedCategory.id == cat.id ||
                selectedCategory.name.toLowerCase() == cat.name.toLowerCase();
            return CategoryChip(
              category: cat,
              isSelected: isSelected,
              onSelected: onCategoryChanged,
            );
          }).toList(),
        ),
      ],
    );
  }
}
