import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/expense_item_card.dart';
import 'add_transaction_screen.dart';

/// Screen displaying searchable, filterable, and date-grouped transaction history
/// loaded directly from the local SQLite database.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Displays confirmation dialog before deleting a transaction from SQLite.
  void _confirmDeleteTransaction(
      BuildContext context, ExpenseProvider provider, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.deleteExpense(expense.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${expense.title}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      provider.addExpense(expense);
                    },
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Opens a detail bottom sheet displaying complete transaction information.
  void _showTransactionDetailsModal(
      BuildContext context, ExpenseProvider provider, Expense expense) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Icon & Title Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: expense.category.color.withAlpha(30),
                    child: Icon(
                      expense.category.icon,
                      color: expense.category.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (expense.isIncome
                                    ? AppColors.incomeGreen
                                    : AppColors.expenseRed)
                                .withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expense.isIncome ? 'INCOME' : 'EXPENSE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: expense.isIncome
                                  ? AppColors.incomeGreen
                                  : AppColors.expenseRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Amount Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (expense.isIncome
                          ? AppColors.incomeGreen
                          : AppColors.expenseRed)
                      .withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${expense.isIncome ? "+" : "-"}${Formatters.formatCurrency(expense.amount)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: expense.isIncome
                            ? AppColors.incomeGreen
                            : AppColors.expenseRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details List
              _buildDetailRow(context, 'Category', expense.category.name),
              _buildDetailRow(
                  context, 'Date', Formatters.formatDate(expense.date)),
              if (expense.note != null && expense.note!.isNotEmpty)
                _buildDetailRow(context, 'Description', expense.note!),
              const SizedBox(height: 24),

              // Edit & Delete Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _confirmDeleteTransaction(context, provider, expense);
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.expenseRed),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.expenseRed),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              existingExpense: expense,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final groupedMap = provider.groupedExpensesByDate;
        final totalCount = provider.filteredExpenses.length;
        final allCategoriesList = provider.allCategories;

        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search title or description...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (val) => provider.setSearchQuery(val),
                  )
                : const Text(
                    'Transaction History',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
            actions: [
              // Search Toggle
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                ),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _isSearching = false;
                      _searchController.clear();
                      provider.setSearchQuery('');
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
              // Sort Order Toggle (Newest vs Oldest)
              PopupMenuButton<SortOrder>(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Sort order',
                onSelected: (order) => provider.setSortOrder(order),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: SortOrder.newestFirst,
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 18,
                          color: provider.sortOrder == SortOrder.newestFirst
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('Newest First'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SortOrder.oldestFirst,
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 18,
                          color: provider.sortOrder == SortOrder.oldestFirst
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('Oldest First'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              // Filter Bar Section
              Container(
                padding: const EdgeInsets.only(
                  left: AppConstants.paddingMedium,
                  right: AppConstants.paddingMedium,
                  bottom: AppConstants.paddingSmall,
                ),
                child: Column(
                  children: [
                    // 1. Type Filter Chips (All, Income, Expense)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeFilterChip(
                            context,
                            title: 'All Types',
                            filter: TransactionFilter.all,
                            activeFilter: provider.currentFilter,
                            onTap: () => provider.setFilter(TransactionFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeFilterChip(
                            context,
                            title: 'Income',
                            filter: TransactionFilter.income,
                            activeFilter: provider.currentFilter,
                            onTap: () =>
                                provider.setFilter(TransactionFilter.income),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeFilterChip(
                            context,
                            title: 'Expenses',
                            filter: TransactionFilter.expense,
                            activeFilter: provider.currentFilter,
                            onTap: () =>
                                provider.setFilter(TransactionFilter.expense),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Date Range Filter Chips (This Month, This Week, Last Month, All Time)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDateFilterChip(
                            context,
                            title: 'This Month',
                            filter: DateRangeFilter.thisMonth,
                            activeFilter: provider.currentDateFilter,
                            onTap: () =>
                                provider.setDateFilter(DateRangeFilter.thisMonth),
                          ),
                          const SizedBox(width: 8),
                          _buildDateFilterChip(
                            context,
                            title: 'This Week',
                            filter: DateRangeFilter.thisWeek,
                            activeFilter: provider.currentDateFilter,
                            onTap: () =>
                                provider.setDateFilter(DateRangeFilter.thisWeek),
                          ),
                          const SizedBox(width: 8),
                          _buildDateFilterChip(
                            context,
                            title: 'Last Month',
                            filter: DateRangeFilter.lastMonth,
                            activeFilter: provider.currentDateFilter,
                            onTap: () =>
                                provider.setDateFilter(DateRangeFilter.lastMonth),
                          ),
                          const SizedBox(width: 8),
                          _buildDateFilterChip(
                            context,
                            title: 'All Time',
                            filter: DateRangeFilter.allTime,
                            activeFilter: provider.currentDateFilter,
                            onTap: () =>
                                provider.setDateFilter(DateRangeFilter.allTime),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3. Category Filter List
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryFilterChip(
                            context,
                            categoryName: null,
                            activeCategory: provider.selectedCategoryFilter,
                            displayName: 'All Categories',
                            onTap: () => provider.setCategoryFilter(null),
                          ),
                          ...allCategoriesList.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildCategoryFilterChip(
                                context,
                                categoryName: cat.name,
                                activeCategory: provider.selectedCategoryFilter,
                                displayName: cat.name,
                                color: cat.color,
                                onTap: () => provider.setCategoryFilter(cat.name),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Results Counter & Active Sort Indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing $totalCount records',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      provider.sortOrder == SortOrder.newestFirst
                          ? 'Sorted: Newest ⬇'
                          : 'Sorted: Oldest ⬆',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Grouped Transactions List or Empty State
              Expanded(
                child: groupedMap.isEmpty
                    ? const EmptyStateWidget(
                        message: 'No Transactions Found',
                        subMessage:
                            'Try adjusting your search query, type, or date filters to view records.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                        ),
                        itemCount: groupedMap.keys.length,
                        itemBuilder: (context, index) {
                          final date = groupedMap.keys.elementAt(index);
                          final items = groupedMap[date]!;
                          final dailyTotal = items.fold(
                            0.0,
                            (sum, i) =>
                                sum + (i.isIncome ? i.amount : -i.amount),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 14,
                                  bottom: 6,
                                  left: 4,
                                  right: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatGroupHeaderDate(date),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${dailyTotal >= 0 ? '+' : ''}${Formatters.formatCurrency(dailyTotal)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: dailyTotal >= 0
                                            ? AppColors.incomeGreen
                                            : AppColors.expenseRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Transaction Item Cards
                              ...items.map(
                                (expense) => ExpenseItemCard(
                                  expense: expense,
                                  onTap: () {
                                    _showTransactionDetailsModal(
                                      context,
                                      provider,
                                      expense,
                                    );
                                  },
                                  onDelete: () {
                                    _confirmDeleteTransaction(
                                      context,
                                      provider,
                                      expense,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'history_fab',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(),
                ),
              );
            },
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  String _formatGroupHeaderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) return 'Today';
    if (check == yesterday) return 'Yesterday';
    return Formatters.formatDate(date);
  }

  Widget _buildTypeFilterChip(
    BuildContext context, {
    required String title,
    required TransactionFilter filter,
    required TransactionFilter activeFilter,
    required VoidCallback onTap,
  }) {
    final isSelected = filter == activeFilter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationDurationShort,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white24 : Colors.grey[300]!),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(
    BuildContext context, {
    required String title,
    required DateRangeFilter filter,
    required DateRangeFilter activeFilter,
    required VoidCallback onTap,
  }) {
    final isSelected = filter == activeFilter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationDurationShort,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(isDark ? 60 : 30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white12 : Colors.grey[300]!),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip(
    BuildContext context, {
    required String? categoryName,
    required String? activeCategory,
    required String displayName,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isSelected = (categoryName == null && activeCategory == null) ||
        (categoryName != null &&
            activeCategory != null &&
            categoryName.toLowerCase() == activeCategory.toLowerCase());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationDurationShort,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(isDark ? 80 : 30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white12 : Colors.grey[300]!),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          displayName,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? Colors.white : activeColor)
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
