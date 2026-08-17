import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/charts/donut_chart_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../analytics/analytics_charts_screen.dart';

/// Comprehensive Monthly Reports Screen powered by local SQLite database.
class MonthlyReportsScreen extends StatefulWidget {
  const MonthlyReportsScreen({super.key});

  @override
  State<MonthlyReportsScreen> createState() => _MonthlyReportsScreenState();
}

class _MonthlyReportsScreenState extends State<MonthlyReportsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Report Month',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        // 1. Current Selected Month Calculations from SQLite
        final income = provider.getIncomeForMonth(_selectedMonth);
        final expense = provider.getExpenseForMonth(_selectedMonth);
        final balance = income - expense;

        final incomeCount = provider.getIncomeCountForMonth(_selectedMonth);
        final expenseCount = provider.getExpenseCountForMonth(_selectedMonth);

        final highestExpenseItem =
            provider.getHighestExpenseForMonth(_selectedMonth);
        final topCategoryEntry =
            provider.getTopSpendingCategoryForMonth(_selectedMonth);
        final categoryMap =
            provider.getCategoryExpensesForMonth(_selectedMonth);
        final dailyMap = provider.getDailyExpensesForMonth(_selectedMonth);

        // 2. Previous Month Calculations for Comparison
        final prevMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
        final prevIncome = provider.getIncomeForMonth(prevMonth);
        final prevExpense = provider.getExpenseForMonth(prevMonth);
        final prevBalance = prevIncome - prevExpense;

        // Income Change
        final incomeDiff = income - prevIncome;
        final incomePctChange =
            prevIncome > 0 ? (incomeDiff / prevIncome) * 100 : 0.0;

        // Expense Change
        final expenseDiff = expense - prevExpense;
        final expensePctChange =
            prevExpense > 0 ? (expenseDiff / prevExpense) * 100 : 0.0;

        // Balance Change
        final balanceDiff = balance - prevBalance;
        final balancePctChange = prevBalance.abs() > 0
            ? (balanceDiff / prevBalance.abs()) * 100
            : 0.0;

        final hasTransactions = (incomeCount + expenseCount) > 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Monthly Financial Report',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Visual Analytics',
                icon: const Icon(Icons.analytics_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AnalyticsScreen(),
                    ),
                  );
                },
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
                  // 1. Month Selector Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => _changeMonth(-1),
                            tooltip: 'Previous Month',
                          ),
                          GestureDetector(
                            onTap: _pickMonth,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMMM yyyy').format(_selectedMonth),
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
                            onPressed: () => _changeMonth(1),
                            tooltip: 'Next Month',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Financial Overview Cards (Income, Expense, Net Balance)
                  _buildOverviewCards(
                    context,
                    income: income,
                    expense: expense,
                    balance: balance,
                  ),
                  const SizedBox(height: 16),

                  // 3. Month-over-Month Comparison Section
                  _buildComparisonSection(
                    context,
                    prevMonthName: DateFormat('MMM').format(prevMonth),
                    incomeDiff: incomeDiff,
                    incomePct: incomePctChange,
                    expenseDiff: expenseDiff,
                    expensePct: expensePctChange,
                    balanceDiff: balanceDiff,
                    balancePct: balancePctChange,
                  ),
                  const SizedBox(height: 16),

                  if (!hasTransactions)
                    const EmptyStateWidget(
                      message: 'No Transactions for this Month',
                      subMessage:
                          'Select a different month or add transactions to see detailed reports.',
                    )
                  else ...[
                    // 4. Transaction Statistics (Counts & Highlights)
                    _buildTransactionHighlights(
                      context,
                      incomeCount: incomeCount,
                      expenseCount: expenseCount,
                      highestExpense: highestExpenseItem,
                      topCategoryEntry: topCategoryEntry,
                    ),
                    const SizedBox(height: 16),

                    // 5. Category-wise Expenses Breakdown
                    _buildCategoryBreakdownCard(
                      context,
                      categoryMap: categoryMap,
                      totalExpense: expense,
                    ),
                    const SizedBox(height: 16),

                    // 6. Daily Spending Summary Grid / List
                    _buildDailySpendingSummary(
                      context,
                      dailyMap: dailyMap,
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

  /// 2. Overview Cards Component (Income, Expense, Net Balance)
  Widget _buildOverviewCards(
    BuildContext context, {
    required double income,
    required double expense,
    required double balance,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : Colors.grey.withAlpha(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewItem(context, 'Total Income', income, AppColors.incomeGreen,
                  Icons.arrow_downward_rounded),
              Container(
                  width: 1, height: 44, color: Colors.grey.withAlpha(40)),
              _buildOverviewItem(context, 'Total Expense', expense, AppColors.expenseRed,
                  Icons.arrow_upward_rounded),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Balance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                '${balance >= 0 ? '+' : ''}${provider.formatCurrency(balance)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: balance >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
      BuildContext context, String label, double amount, Color color, IconData icon) {
    final provider = Provider.of<ExpenseProvider>(context);

    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    provider.formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Month-over-Month Comparison Section
  Widget _buildComparisonSection(
    BuildContext context, {
    required String prevMonthName,
    required double incomeDiff,
    required double incomePct,
    required double expenseDiff,
    required double expensePct,
    required double balanceDiff,
    required double balancePct,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparison vs $prevMonthName',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonTile(
                    context,
                    label: 'Income',
                    diff: incomeDiff,
                    pct: incomePct,
                    isGoodWhenIncreased: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildComparisonTile(
                    context,
                    label: 'Expense',
                    diff: expenseDiff,
                    pct: expensePct,
                    isGoodWhenIncreased: false, // Lower expense is good
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildComparisonTile(
                    context,
                    label: 'Balance',
                    diff: balanceDiff,
                    pct: balancePct,
                    isGoodWhenIncreased: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTile(
    BuildContext context, {
    required String label,
    required double diff,
    required double pct,
    required bool isGoodWhenIncreased,
  }) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isPositive = diff > 0;
    final isZero = diff == 0;

    Color color;
    IconData icon;
    String direction;

    if (isZero) {
      color = Colors.grey;
      icon = Icons.remove_rounded;
      direction = 'No change';
    } else if (isPositive) {
      color = isGoodWhenIncreased ? AppColors.incomeGreen : AppColors.expenseRed;
      icon = Icons.arrow_upward_rounded;
      direction = 'Increased';
    } else {
      color = isGoodWhenIncreased ? AppColors.expenseRed : AppColors.incomeGreen;
      icon = Icons.arrow_downward_rounded;
      direction = 'Decreased';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${diff >= 0 ? '+' : ''}${provider.formatCurrencyCompact(diff)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isZero ? '0.0%' : '$direction (${pct.abs().toStringAsFixed(0)}%)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Transaction Statistics Highlights Component
  Widget _buildTransactionHighlights(
    BuildContext context, {
    required int incomeCount,
    required int expenseCount,
    required Expense? highestExpense,
    required MapEntry<ExpenseCategory, double>? topCategoryEntry,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity & Highlights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHighlightBadge(
                    context,
                    label: 'Income Records',
                    value: '$incomeCount entries',
                    icon: Icons.south_west_rounded,
                    color: AppColors.incomeGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildHighlightBadge(
                    context,
                    label: 'Expense Records',
                    value: '$expenseCount entries',
                    icon: Icons.north_east_rounded,
                    color: AppColors.expenseRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (highestExpense != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.expenseRed.withAlpha(25),
                      child: const Icon(
                        Icons.priority_high_rounded,
                        color: AppColors.expenseRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Highest Expense',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            highestExpense.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-${provider.formatCurrency(highestExpense.amount)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.expenseRed,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightBadge(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Category Breakdown Component
  Widget _buildCategoryBreakdownCard(
    BuildContext context, {
    required Map<ExpenseCategory, double> categoryMap,
    required double totalExpense,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context);

    if (categoryMap.isEmpty) return const SizedBox.shrink();

    final entries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category-wise Expenses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DonutChartWidget(
              categoryAmounts: categoryMap,
              totalAmount: totalExpense,
              size: 140,
            ),
            const SizedBox(height: 20),
            ...entries.map((entry) {
              final cat = entry.key;
              final amt = entry.value;
              final pct = totalExpense > 0 ? (amt / totalExpense) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: cat.color.withAlpha(30),
                          child: Icon(cat.icon, color: cat.color, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          provider.formatCurrency(amt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${(pct * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.grey.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 6. Daily Spending Summary Component
  Widget _buildDailySpendingSummary(
    BuildContext context, {
    required Map<int, double> dailyMap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context);

    // Filter days with spending
    final activeDays =
        dailyMap.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.key.compareTo(a.key));

    if (activeDays.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Spending Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeDays.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final dayEntry = activeDays[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Day ${dayEntry.key}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        provider.formatCurrency(dayEntry.value),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
