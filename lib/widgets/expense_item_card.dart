import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Card widget to display a single expense or income record.
class ExpenseItemCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ExpenseItemCard({
    super.key,
    required this.expense,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expenseRed,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) {
        if (onDelete != null) onDelete!();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                // Category Icon with colored background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: expense.category.color.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Icon(
                    expense.category.icon,
                    color: expense.category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            Formatters.formatRelativeDate(expense.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (expense.note != null && expense.note!.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                expense.note!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount
                Text(
                  '${expense.isIncome ? '+' : '-'}${expenseProvider.formatCurrency(expense.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: expense.isIncome
                        ? AppColors.incomeGreen
                        : (isDark ? const Color(0xFFEF5350) : AppColors.expenseRed),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
