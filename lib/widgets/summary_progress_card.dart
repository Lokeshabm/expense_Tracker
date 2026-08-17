import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Card widget displaying Monthly Expense Summary & Budget Progress.
class MonthlyBudgetSummaryCard extends StatelessWidget {
  final double spent;
  final double budget;
  final double savingsRate;
  final VoidCallback? onAdjustBudget;

  const MonthlyBudgetSummaryCard({
    super.key,
    required this.spent,
    required this.budget,
    required this.savingsRate,
    this.onAdjustBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > budget && budget > 0;
    final remaining = budget - spent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Expense Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? AppColors.expenseRed.withAlpha(25)
                        : AppColors.incomeGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Text(
                    isOverBudget
                        ? 'Over Budget'
                        : '${(progress * 100).toStringAsFixed(0)}% of Budget',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isOverBudget
                          ? AppColors.expenseRed
                          : AppColors.incomeGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: isDark
                    ? Colors.white.withAlpha(20)
                    : Colors.grey.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? AppColors.expenseRed
                      : progress > 0.85
                          ? Colors.orange
                          : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent this month',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(spent),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      remaining >= 0 ? 'Remaining' : 'Overspent by',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(remaining.abs()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remaining >= 0
                            ? AppColors.incomeGreen
                            : AppColors.expenseRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Category spending item progress row.
class CategorySpendingSummaryItem extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double totalExpense;

  const CategorySpendingSummaryItem({
    super.key,
    required this.category,
    required this.amount,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = totalExpense > 0 ? (amount / totalExpense) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.color.withAlpha(isDark ? 50 : 30),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Icon(
                  category.icon,
                  size: 18,
                  color: category.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(amount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                      child: LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withAlpha(15)
                            : Colors.grey.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(category.color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
