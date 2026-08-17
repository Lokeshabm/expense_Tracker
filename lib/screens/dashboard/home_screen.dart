import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/income_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/recent_transaction_card.dart';
import '../categories/categories_screen.dart';
import '../transactions/add_transaction_screen.dart';

/// Fully functional Dashboard Screen powered by SQLite database.
class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToHistory;

  const HomeScreen({
    super.key,
    this.onNavigateToHistory,
  });

  /// Navigates back/forward between months for the Dashboard
  void _changeMonth(BuildContext context, ExpenseProvider provider, int offset) {
    final current = provider.selectedDashboardMonth;
    final newMonth = DateTime(current.year, current.month + offset, 1);
    provider.setSelectedDashboardMonth(newMonth);
  }

  /// Opens standard month picker dialog
  Future<void> _pickMonth(BuildContext context, ExpenseProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDashboardMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Dashboard Month',
    );
    if (picked != null) {
      provider.setSelectedDashboardMonth(DateTime(picked.year, picked.month, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<ExpenseProvider, AuthProvider>(
      builder: (context, expenseProvider, authProvider, child) {
        final selectedMonth = expenseProvider.selectedDashboardMonth;
        final userName = authProvider.userDisplayName;

        // Dashboard Statistics calculated from SQLite
        final currentBalance = expenseProvider.netBalance; // Formula: Total Income - Total Expenses
        final monthIncome = expenseProvider.getIncomeForMonth(selectedMonth);
        final monthExpense = expenseProvider.getExpenseForMonth(selectedMonth);
        final transactionCount = expenseProvider.getTransactionCountForMonth(selectedMonth);
        final recentList = expenseProvider.getRecentTransactionsForMonth(selectedMonth);
        final topCategoryEntry = expenseProvider.getTopSpendingCategoryForMonth(selectedMonth);

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => expenseProvider.loadTransactions(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Top Custom App Bar
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withAlpha(40),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good day, $userName 👋',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Manage Categories',
                      icon: const Icon(Icons.category_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Refresh SQLite Data',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => expenseProvider.loadTransactions(),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // 1. Month Selector Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: 4,
                    ),
                    child: Container(
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
                            onPressed: () =>
                                _changeMonth(context, expenseProvider, -1),
                            tooltip: 'Previous Month',
                          ),
                          GestureDetector(
                            onTap: () => _pickMonth(context, expenseProvider),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMMM yyyy').format(selectedMonth),
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
                            onPressed: () =>
                                _changeMonth(context, expenseProvider, 1),
                            tooltip: 'Next Month',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Current Balance Card (Formula: Total Income - Total Expenses)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingSmall,
                    ),
                    child: BalanceCard(
                      netBalance: currentBalance,
                      totalIncome: expenseProvider.totalIncome,
                      totalExpense: expenseProvider.totalExpense,
                    ),
                  ),
                ),

                // 3. Monthly Income & Expense Cards Side-by-Side
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: IncomeCard(
                            amount: monthIncome,
                            label: 'Monthly Income',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ExpenseCard(
                            amount: monthExpense,
                            label: 'Monthly Expenses',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Quick Action Buttons (Quick Add Income & Quick Add Expense)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingSmall,
                    ),
                    child: Row(
                      children: [
                        QuickActionButton(
                          label: 'Quick Add Income',
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.incomeGreen,
                          backgroundColor: AppColors.incomeGreenLight,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen(
                                  initialIsIncome: true,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        QuickActionButton(
                          label: 'Quick Add Expense',
                          icon: Icons.arrow_upward_rounded,
                          color: AppColors.expenseRed,
                          backgroundColor: AppColors.expenseRedLight,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen(
                                  initialIsIncome: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Month Summary Info Tile (Transaction Count & Top Spending Category)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: 4,
                    ),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        child: Row(
                          children: [
                            // Total count
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Transactions',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      Text(
                                        '$transactionCount items',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: Colors.grey.withAlpha(40)),
                            const SizedBox(width: 12),
                            // Top Spending Category
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (topCategoryEntry?.key.color ??
                                              Colors.amber)
                                          .withAlpha(25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      topCategoryEntry?.key.icon ??
                                          Icons.star_rounded,
                                      size: 18,
                                      color: topCategoryEntry?.key.color ??
                                          Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Top Category',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        Text(
                                          topCategoryEntry != null
                                              ? topCategoryEntry.key.name
                                              : 'None',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Recent Transactions Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppConstants.paddingMedium,
                      right: AppConstants.paddingMedium,
                      top: AppConstants.paddingLarge,
                      bottom: AppConstants.paddingSmall,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (onNavigateToHistory != null)
                          GestureDetector(
                            onTap: onNavigateToHistory,
                            child: const Text(
                              'View History',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 7. Recent Transactions List
                if (recentList.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyStateWidget(
                      message: 'No Transactions for this Month',
                      subMessage:
                          'Use the Quick Add buttons above to add a new income or expense.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: AppConstants.paddingMedium,
                      right: AppConstants.paddingMedium,
                      bottom: 80,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final expense = recentList[index];
                          return RecentTransactionCard(
                            expense: expense,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddTransactionScreen(
                                    existingExpense: expense,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: recentList.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
