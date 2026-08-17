import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

/// Reusable Bar Chart comparing Monthly Income vs Expenses using `fl_chart`.
class IncomeExpenseBarChart extends StatelessWidget {
  final List<MonthlyBarData> barDataList;

  const IncomeExpenseBarChart({
    super.key,
    required this.barDataList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find max value to calibrate Y-axis
    double maxVal = 100.0;
    for (final item in barDataList) {
      if (item.income > maxVal) maxVal = item.income;
      if (item.expense > maxVal) maxVal = item.expense;
    }
    maxVal *= 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Income vs Expense (6 Months)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendItem('Income', AppColors.incomeGreen),
                    const SizedBox(width: 12),
                    _buildLegendItem('Expense', AppColors.expenseRed),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          isDark ? Colors.grey[800]! : Colors.grey[900]!,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = rodIndex == 0 ? 'Income' : 'Expense';
                        return BarTooltipItem(
                          '$type\n${Formatters.formatCurrency(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            Formatters.formatCompactCurrency(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < barDataList.length) {
                            final month = barDataList[idx].month;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('MMM').format(month),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barDataList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.income,
                          color: AppColors.incomeGreen,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: data.expense,
                          color: AppColors.expenseRed,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
