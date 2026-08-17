import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../utils/constants.dart';

/// Reusable Pie Chart displaying expense breakdown by category using `fl_chart`.
class CategoryPieChart extends StatefulWidget {
  final Map<ExpenseCategory, double> categoryData;
  final double totalExpense;

  const CategoryPieChart({
    super.key,
    required this.categoryData,
    required this.totalExpense,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.totalExpense <= 0 || widget.categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense by Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: List.generate(entries.length, (i) {
                    final isTouched = i == touchedIndex;
                    final fontSize = isTouched ? 14.0 : 11.0;
                    final radius = isTouched ? 65.0 : 55.0;
                    final entry = entries[i];
                    final percentage = (entry.value / widget.totalExpense) * 100;

                    return PieChartSectionData(
                      color: entry.key.color,
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 2),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Dynamic Legend Grid
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: entries.map((entry) {
                final percentage = (entry.value / widget.totalExpense) * 100;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: entry.key.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key.name} (${percentage.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
