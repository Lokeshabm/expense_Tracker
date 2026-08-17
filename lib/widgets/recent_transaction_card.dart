import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Reusable card displaying an individual transaction item on the Dashboard.
class RecentTransactionCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RecentTransactionCard({
    super.key,
    required this.expense,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categoryColor = expense.category.color;
    final isIncome = expense.isIncome;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: categoryColor.withAlpha(isDark ? 50 : 30),
          child: Icon(
            expense.category.icon,
            color: categoryColor,
            size: 20,
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              expense.category.name,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 6),
            const Text('•', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(width: 6),
            Text(
              Formatters.formatDate(expense.date),
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${expenseProvider.formatCurrency(expense.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
          ),
        ),
      ),
    );
  }
}
