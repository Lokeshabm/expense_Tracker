import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

/// Donut / Ring chart widget displaying category percentage distribution.
class DonutChartWidget extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryAmounts;
  final double totalAmount;
  final double size;

  const DonutChartWidget({
    super.key,
    required this.categoryAmounts,
    required this.totalAmount,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _DonutChartPainter(
                categoryAmounts: categoryAmounts,
                totalAmount: totalAmount,
                isDark: isDark,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Spent',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      Formatters.formatCurrency(totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> categoryAmounts;
  final double totalAmount;
  final bool isDark;

  _DonutChartPainter({
    required this.categoryAmounts,
    required this.totalAmount,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    const strokeWidth = 18.0;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(30);

    canvas.drawCircle(center, radius, basePaint);

    if (totalAmount <= 0 || categoryAmounts.isEmpty) return;

    double startAngle = -pi / 2;

    for (final entry in categoryAmounts.entries) {
      final sweepAngle = (entry.value / totalAmount) * 2 * pi;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = entry.key.color;

      // Small gap between segments
      final gap = sweepAngle > 0.1 ? 0.04 : 0.0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweepAngle - gap,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.totalAmount != totalAmount ||
        oldDelegate.categoryAmounts != categoryAmounts ||
        oldDelegate.isDark != isDark;
  }
}
