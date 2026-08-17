import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

/// Clean, high-performance Custom Bar Chart widget for weekly or monthly trends.
class BarChartWidget extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final Color barColor;
  final int selectedIndex;
  final ValueChanged<int>? onBarSelected;

  const BarChartWidget({
    super.key,
    required this.values,
    required this.labels,
    this.height = 180,
    this.barColor = AppColors.primary,
    this.selectedIndex = -1,
    this.onBarSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxVal = values.isEmpty ? 1.0 : max(values.reduce(max), 10.0);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final val = values[index];
          final pct = (val / maxVal).clamp(0.05, 1.0);
          final label = index < labels.length ? labels[index] : '';
          final isSelected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onBarSelected?.call(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value tooltip above bar if selected or top item
                  if (isSelected || val == maxVal)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Formatters.formatCurrencyCompact(val),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  const SizedBox(height: 4),
                  // Animated Bar
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: pct,
                        child: AnimatedContainer(
                          duration: AppConstants.animationDurationShort,
                          width: isSelected ? 22 : 16,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isSelected
                                  ? [AppColors.primaryDark, AppColors.primaryLight]
                                  : [
                                      barColor.withAlpha(isDark ? 150 : 180),
                                      barColor,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(100),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
