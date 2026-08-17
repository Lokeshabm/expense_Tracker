import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/constants.dart';

/// Selectable category chip for filters and creation forms.
class CategoryChip extends StatelessWidget {
  final ExpenseCategory category;
  final bool isSelected;
  final ValueChanged<ExpenseCategory> onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onSelected(category),
      child: AnimatedContainer(
        duration: AppConstants.animationDurationShort,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withAlpha(isDark ? 80 : 40)
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(
            color: isSelected
                ? category.color
                : (isDark ? Colors.white.withAlpha(20) : Colors.grey.withAlpha(40)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 18,
              color: isSelected ? category.color : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : category.color)
                    : (isDark ? Colors.grey[300] : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
