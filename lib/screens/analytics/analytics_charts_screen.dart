import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/category_summary_list.dart';
import '../../widgets/charts/daily_expenses_line_chart.dart';
import '../../widgets/charts/income_expense_bar_chart.dart';
import '../../widgets/empty_state_widget.dart';

/// AnalyticsScreen displaying interactive fl_charts powered by local SQLite transaction data.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  void _changeMonth(BuildContext context, ExpenseProvider provider, int offset) {
    final current = provider.selectedAnalyticsMonth;
    final newMonth = DateTime(current.year, current.month + offset, 1);
    provider.setSelectedAnalyticsMonth(newMonth);
  }

  Future<void> _pickMonth(BuildContext context, ExpenseProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedAnalyticsMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Analytics Month',
    );
    if (picked != null) {
      provider.setSelectedAnalyticsMonth(DateTime(picked.year, picked.month, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final month = provider.selectedAnalyticsMonth;
        final monthIncome = provider.getIncomeForMonth(month);
        final monthExpense = provider.getExpenseForMonth(month);
        final netSavings = monthIncome - monthExpense;
        final savingsRate = monthIncome > 0
            ? ((netSavings / monthIncome) * 100).clamp(0.0, 100.0)
            : 0.0;

        final dailyMap = provider.getDailyExpensesForMonth(month);
        final categoryMap = provider.getCategoryExpensesForMonth(month);
        final barDataList = provider.getTrailing6MonthsBarData(month);
        final topCategoryEntry = provider.getTopSpendingCategoryForMonth(month);

        final hasData = monthIncome > 0 || monthExpense > 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Analytics & Charts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Analytics',
                onPressed: () => provider.loadTransactions(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.loadTransactions(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Interactive Month Selector Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(15)
                          : Colors.grey.withAlpha(20),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () => _changeMonth(context, provider, -1),
                          tooltip: 'Previous Month',
                        ),
                        GestureDetector(
                          onTap: () => _pickMonth(context, provider),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.analytics_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMMM yyyy').format(month),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () => _changeMonth(context, provider, 1),
                          tooltip: 'Next Month',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Summary KPI Metrics Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildKpiItem(
                                context,
                                label: 'Month Income',
                                value: provider.formatCurrency(monthIncome),
                                color: AppColors.incomeGreen,
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: Colors.grey.withAlpha(40),
                              ),
                              _buildKpiItem(
                                context,
                                label: 'Month Expense',
                                value: provider.formatCurrency(monthExpense),
                                color: AppColors.expenseRed,
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: Colors.grey.withAlpha(40),
                              ),
                              _buildKpiItem(
                                context,
                                label: 'Savings Rate',
                                value: '${savingsRate.toStringAsFixed(0)}%',
                                color: savingsRate >= 20
                                    ? AppColors.incomeGreen
                                    : Colors.orange,
                              ),
                            ],
                          ),
                          if (topCategoryEntry != null) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Top Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      topCategoryEntry.key.icon,
                                      size: 16,
                                      color: topCategoryEntry.key.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${topCategoryEntry.key.name} (${provider.formatCurrency(topCategoryEntry.value)})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!hasData)
                    const EmptyStateWidget(
                      message: 'No Transaction Data for this Month',
                      subMessage:
                          'Select a different month or add transactions to populate charts.',
                    )
                  else ...[
                    // Chart 1: Income vs Expense Bar Chart
                    IncomeExpenseBarChart(barDataList: barDataList),
                    const SizedBox(height: 16),

                    // Chart 2: Category Expense Pie Chart
                    CategoryPieChart(
                      categoryData: categoryMap,
                      totalExpense: monthExpense,
                    ),
                    const SizedBox(height: 16),

                    // Chart 3: Daily Expenses Line Chart
                    DailyExpensesLineChart(dailyExpenses: dailyMap),
                    const SizedBox(height: 16),

                    // Chart 4: Category Summary List & Progress Bars
                    CategorySummaryList(
                      categoryData: categoryMap,
                      totalExpense: monthExpense,
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
