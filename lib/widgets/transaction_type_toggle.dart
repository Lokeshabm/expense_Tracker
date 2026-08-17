import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

/// Reusable Segmented Toggle Switch for selecting Income or Expense type.
class TransactionTypeToggle extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;

  const TransactionTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = selectedType == TransactionType.expense;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Row(
        children: [
          // Expense Segment
          Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged(TransactionType.expense),
              child: AnimatedContainer(
                duration: AppConstants.animationDurationShort,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isExpense
                      ? (isDark ? AppColors.cardDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  boxShadow: isExpense
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: isExpense ? AppColors.expenseRed : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expense',
                      style: TextStyle(
                        fontWeight:
                            isExpense ? FontWeight.bold : FontWeight.w500,
                        color: isExpense
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Income Segment
          Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged(TransactionType.income),
              child: AnimatedContainer(
                duration: AppConstants.animationDurationShort,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isExpense
                      ? (isDark ? AppColors.cardDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  boxShadow: !isExpense
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 18,
                      color: !isExpense ? AppColors.incomeGreen : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Income',
                      style: TextStyle(
                        fontWeight:
                            !isExpense ? FontWeight.bold : FontWeight.w500,
                        color: !isExpense
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
