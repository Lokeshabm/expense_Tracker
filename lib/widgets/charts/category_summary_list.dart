import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';

/// Reusable Category-wise Expense Summary list showing category icon, name, total amount, and percentage bar.
class CategorySummaryList extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryData;
  final double totalExpense;

  const CategorySummaryList({
    super.key,
    required this.categoryData,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (categoryData.isEmpty || totalExpense <= 0) {
      return const SizedBox.shrink();
    }

    final entries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Expense Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...entries.map((entry) {
              final category = entry.key;
              final amount = entry.value;
              final percentage = (amount / totalExpense);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: category.color.withAlpha(30),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(percentage * 100).toStringAsFixed(1)}% of total expenses',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Provider.of<ExpenseProvider>(context).formatCurrency(amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.grey.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(category.color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
