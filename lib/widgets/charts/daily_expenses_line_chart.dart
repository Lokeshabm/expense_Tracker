import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

/// Reusable Line Chart displaying daily expense trends for a selected month using `fl_chart`.
class DailyExpensesLineChart extends StatelessWidget {
  final Map<int, double> dailyExpenses;

  const DailyExpensesLineChart({
    super.key,
    required this.dailyExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (dailyExpenses.isEmpty) return const SizedBox.shrink();

    // Generate FlSpots from daily map
    final sortedDays = dailyExpenses.keys.toList()..sort();
    final spots = sortedDays
        .map((day) => FlSpot(day.toDouble(), dailyExpenses[day] ?? 0.0))
        .toList();

    double maxY = 100.0;
    for (final val in dailyExpenses.values) {
      if (val > maxY) maxY = val;
    }
    maxY *= 1.2;

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
                  'Daily Expenses Trend',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.expenseRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Daily Track',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expenseRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                      strokeWidth: 1,
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
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt();
                          if (day > 0 && day <= sortedDays.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Day $day',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 1,
                  maxX: sortedDays.length.toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) =>
                          isDark ? Colors.grey[800]! : Colors.grey[900]!,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            'Day ${spot.x.toInt()}\n${Formatters.formatCurrency(spot.y)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.expenseRed,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.expenseRed,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.expenseRed.withAlpha(80),
                            AppColors.expenseRed.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
