import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/category_model.dart';
import '../models/expense.dart';
import '../models/transaction_model.dart';
import '../models/user_profile.dart';
import '../utils/formatters.dart';

enum TransactionFilter { all, expense, income }
enum DateRangeFilter { allTime, thisMonth, lastMonth, thisWeek }
enum SortOrder { newestFirst, oldestFirst }

/// State Management Provider for managing transactions, categories, budgets, currency, and SQLite persistence.
/// Enforces strict userId checking, auto-recovery for missing session keys, and clean memory state.
class ExpenseProvider extends ChangeNotifier {
  static const String _prefCurrencySymbolKey = 'user_currency_symbol';
  static const String _prefCurrencyCodeKey = 'user_currency_code';

  final DatabaseHelper _dbHelper;

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  TransactionFilter _currentFilter = TransactionFilter.all;
  DateRangeFilter _currentDateFilter = DateRangeFilter.thisMonth;
  SortOrder _sortOrder = SortOrder.newestFirst;
  String? _selectedCategoryFilter;
  String _searchQuery = '';
  DateTime _selectedReportMonth = DateTime.now();
  DateTime _selectedDashboardMonth = DateTime.now();
  DateTime _selectedAnalyticsMonth = DateTime.now();
  String _currentUserId = 'user_default';

  String _currencySymbol = '\$';
  String _currencyCode = 'USD';

  UserProfile _userProfile = const UserProfile(
    id: 'user_default',
    name: 'User',
    email: '',
    currency: '\$',
    monthlyBudget: 1500.00,
    enableNotifications: true,
    biometricAuth: false,
  );

  ExpenseProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance {
    _loadSavedCurrency();
  }

  /// Loads saved currency preferences from local storage upon provider initialization.
  Future<void> _loadSavedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSymbol = prefs.getString(_prefCurrencySymbolKey);
      final savedCode = prefs.getString(_prefCurrencyCodeKey);
      if (savedSymbol != null &&
          savedSymbol.isNotEmpty &&
          savedCode != null &&
          savedCode.isNotEmpty) {
        _currencySymbol = savedSymbol;
        _currencyCode = savedCode;
        _userProfile = _userProfile.copyWith(currency: savedSymbol);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Notice loading saved currency: $e');
    }
  }

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<Expense> get expenses => _transactions.map((t) => _toExpense(t)).toList();

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get expenseCategoriesModels =>
      _categories.where((c) => c.isExpense).toList();
  List<CategoryModel> get incomeCategoriesModels =>
      _categories.where((c) => c.isIncome).toList();

  /// Legacy ExpenseCategory adapters for UI compatibility
  List<ExpenseCategory> get allCategories => _categories
      .map((c) => ExpenseCategory(
            id: c.id,
            name: c.name,
            icon: c.iconData,
            color: c.isIncome
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF7043),
            isIncomeCategory: c.isIncome,
          ))
      .toList();

  List<ExpenseCategory> get expenseCategories =>
      allCategories.where((c) => !c.isIncomeCategory).toList();
  List<ExpenseCategory> get incomeCategories =>
      allCategories.where((c) => c.isIncomeCategory).toList();

  bool get isLoading => _isLoading;
  TransactionFilter get currentFilter => _currentFilter;
  DateRangeFilter get currentDateFilter => _currentDateFilter;
  SortOrder get sortOrder => _sortOrder;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;
  DateTime get selectedReportMonth => _selectedReportMonth;
  DateTime get selectedDashboardMonth => _selectedDashboardMonth;
  DateTime get selectedAnalyticsMonth => _selectedAnalyticsMonth;
  UserProfile get userProfile => _userProfile;
  String get currentUserId => _currentUserId;

  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;

  Future<void> setCurrency(String symbol, String code) async {
    if (_currencySymbol != symbol || _currencyCode != code) {
      _currencySymbol = symbol;
      _currencyCode = code;
      _userProfile = _userProfile.copyWith(currency: symbol);
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefCurrencySymbolKey, symbol);
        await prefs.setString(_prefCurrencyCodeKey, code);
      } catch (e) {
        debugPrint('Error saving currency preferences: $e');
      }
    }
  }

  String formatCurrency(double amount) {
    return Formatters.formatCurrency(amount, symbol: _currencySymbol);
  }

  String formatCurrencyCompact(double amount) {
    return Formatters.formatCurrencyCompact(amount, symbol: _currencySymbol);
  }

  /// Updates active user ID and reloads data scoped strictly to the new user.
  void setCurrentUserId(String userId) {
    final cleanUserId = userId.trim();
    final targetId = cleanUserId.isNotEmpty ? cleanUserId : 'user_default';
    if (_currentUserId != targetId) {
      _currentUserId = targetId;
      loadTransactions(_currentUserId);
      loadCategories(_currentUserId);
    }
  }

  /// Clears transient memory when logging out
  void clearInMemoryData() {
    _currentUserId = '';
    _transactions = [];
    _categories = [];
    _searchQuery = '';
    _selectedCategoryFilter = null;
    notifyListeners();
  }

  void setSelectedDashboardMonth(DateTime month) {
    _selectedDashboardMonth = month;
    notifyListeners();
  }

  void setSelectedAnalyticsMonth(DateTime month) {
    _selectedAnalyticsMonth = month;
    notifyListeners();
  }

  /// Converts a TransactionModel to the UI Expense representation.
  Expense _toExpense(TransactionModel model) {
    final isIncome = model.type == TransactionType.income;
    return Expense(
      id: model.id?.toString() ?? '',
      title: model.title,
      amount: model.amount,
      date: model.date,
      category: ExpenseCategory.fromName(model.category, isIncome: isIncome),
      note: model.description,
      isIncome: isIncome,
    );
  }

  /// Filtered and sorted list of expenses based on Search, Type, Category, Date, and Sort order
  List<Expense> get filteredExpenses {
    final now = DateTime.now();
    final list = expenses.where((e) {
      // Type Filter
      if (_currentFilter == TransactionFilter.income && !e.isIncome) return false;
      if (_currentFilter == TransactionFilter.expense && e.isIncome) return false;

      // Category Filter
      if (_selectedCategoryFilter != null && _selectedCategoryFilter!.isNotEmpty) {
        if (e.category.name.toLowerCase() != _selectedCategoryFilter!.toLowerCase()) {
          return false;
        }
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = e.title.toLowerCase().contains(query);
        final matchesCategory = e.category.name.toLowerCase().contains(query);
        final matchesNote = (e.note ?? '').toLowerCase().contains(query);
        if (!matchesTitle && !matchesCategory && !matchesNote) {
          return false;
        }
      }

      // Date Filter
      switch (_currentDateFilter) {
        case DateRangeFilter.thisMonth:
          if (e.date.year != now.year || e.date.month != now.month) return false;
          break;
        case DateRangeFilter.lastMonth:
          final lastMonthDate = DateTime(now.year, now.month - 1, 1);
          if (e.date.year != lastMonthDate.year || e.date.month != lastMonthDate.month) {
            return false;
          }
          break;
        case DateRangeFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfThisWeek =
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          if (e.date.isBefore(startOfThisWeek)) return false;
          break;
        case DateRangeFilter.allTime:
          break;
      }

      return true;
    }).toList();

    // Sort order
    if (_sortOrder == SortOrder.oldestFirst) {
      list.sort((a, b) => a.date.compareTo(b.date));
    } else {
      list.sort((a, b) => b.date.compareTo(a.date));
    }

    return list;
  }

  /// Recent transactions for Dashboard (top 5 overall)
  List<Expense> get recentTransactions => expenses.take(5).toList();

  /// Total sum of all income entries in SQLite
  double get totalIncome {
    return _transactions
        .where((t) => t.type.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Total sum of all expense entries in SQLite
  double get totalExpense {
    return _transactions
        .where((t) => t.type.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Net balance: total income minus total expense
  double get netBalance => totalIncome - totalExpense;

  // ====================================================
  // MONTH-SPECIFIC DASHBOARD & ANALYTICS CALCULATIONS
  // ====================================================

  /// Income for the selected month
  double getIncomeForMonth(DateTime month) {
    return _transactions
        .where((t) =>
            t.type.isIncome &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Expenses for the selected month
  double getExpenseForMonth(DateTime month) {
    return _transactions
        .where((t) =>
            t.type.isExpense &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Balance for the selected month (Income - Expense)
  double getBalanceForMonth(DateTime month) {
    return getIncomeForMonth(month) - getExpenseForMonth(month);
  }

  /// Number of income transactions for selected month
  int getIncomeCountForMonth(DateTime month) {
    return _transactions
        .where((t) =>
            t.type.isIncome &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .length;
  }

  /// Number of expense transactions for selected month
  int getExpenseCountForMonth(DateTime month) {
    return _transactions
        .where((t) =>
            t.type.isExpense &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .length;
  }

  /// Transaction count for selected month
  int getTransactionCountForMonth(DateTime month) {
    return _transactions
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .length;
  }

  /// Highest expense transaction for selected month
  Expense? getHighestExpenseForMonth(DateTime month) {
    final monthExpenses = expenses.where((e) =>
        !e.isIncome && e.date.year == month.year && e.date.month == month.month).toList();
    if (monthExpenses.isEmpty) return null;
    monthExpenses.sort((a, b) => b.amount.compareTo(a.amount));
    return monthExpenses.first;
  }

  /// Recent transactions filtered for selected dashboard month (top 5)
  List<Expense> getRecentTransactionsForMonth(DateTime month) {
    final list = expenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.take(5).toList();
  }

  /// Top spending category for selected month
  MapEntry<ExpenseCategory, double>? getTopSpendingCategoryForMonth(
      DateTime month) {
    final Map<ExpenseCategory, double> breakdown = getCategoryExpensesForMonth(month);
    if (breakdown.isEmpty) return null;
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }

  /// Maps day of month (1..31) to total expenses incurred on that day
  Map<int, double> getDailyExpensesForMonth(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final Map<int, double> dailyMap = {
      for (int i = 1; i <= daysInMonth; i++) i: 0.0
    };

    for (final t in _transactions) {
      if (t.type.isExpense &&
          t.date.year == month.year &&
          t.date.month == month.month) {
        dailyMap[t.date.day] = (dailyMap[t.date.day] ?? 0.0) + t.amount;
      }
    }
    return dailyMap;
  }

  /// Maps ExpenseCategory to total expense amount for selected month
  Map<ExpenseCategory, double> getCategoryExpensesForMonth(DateTime month) {
    final Map<ExpenseCategory, double> breakdown = {};
    for (final t in _transactions.where((t) =>
        t.type.isExpense &&
        t.date.year == month.year &&
        t.date.month == month.month)) {
      final category = ExpenseCategory.fromName(t.category, isIncome: false);
      breakdown[category] = (breakdown[category] ?? 0.0) + t.amount;
    }
    return breakdown;
  }

  /// Trailing 6 months data for BarChart analytics
  List<MonthlyBarData> getTrailing6MonthsBarData(DateTime referenceMonth) {
    final List<MonthlyBarData> result = [];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(referenceMonth.year, referenceMonth.month - i, 1);
      final inc = getIncomeForMonth(m);
      final exp = getExpenseForMonth(m);
      result.add(MonthlyBarData(month: m, income: inc, expense: exp));
    }
    return result;
  }

  /// Current Month Income
  double get thisMonthIncome => getIncomeForMonth(_selectedDashboardMonth);

  /// Current Month Expense
  double get thisMonthExpense => getExpenseForMonth(_selectedDashboardMonth);

  /// Current Month Savings Rate (%)
  double get thisMonthSavingsRate {
    final inc = thisMonthIncome;
    final exp = thisMonthExpense;
    if (inc <= 0) return 0.0;
    return ((inc - exp) / inc * 100).clamp(0.0, 100.0);
  }

  /// Current Month Budget progress (0.0 to 1.0+)
  double get budgetProgress {
    if (_userProfile.monthlyBudget <= 0) return 0.0;
    return thisMonthExpense / _userProfile.monthlyBudget;
  }

  /// Category breakdown: map of expense amounts per category
  Map<ExpenseCategory, double> get categoryBreakdown {
    final Map<ExpenseCategory, double> breakdown = {};
    for (final transaction in _transactions.where((t) => t.type.isExpense)) {
      final category =
          ExpenseCategory.fromName(transaction.category, isIncome: false);
      breakdown[category] = (breakdown[category] ?? 0.0) + transaction.amount;
    }
    return breakdown;
  }

  /// Top spending categories sorted descending with percentages
  List<MapEntry<ExpenseCategory, double>> get topSpendingCategories {
    final list = categoryBreakdown.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  /// Expenses grouped by date for Transaction History
  Map<DateTime, List<Expense>> get groupedExpensesByDate {
    final Map<DateTime, List<Expense>> grouped = {};
    for (final expense in filteredExpenses) {
      final dateOnly =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      grouped.putIfAbsent(dateOnly, () => []).add(expense);
    }
    return grouped;
  }

  /// Daily spending for current week (Mon-Sun)
  List<double> get weeklyDailySpending {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final List<double> daily = List.filled(7, 0.0);

    for (final t in _transactions) {
      if (t.type.isExpense) {
        final diffDays = t.date
            .difference(
                DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day))
            .inDays;
        if (diffDays >= 0 && diffDays < 7) {
          daily[diffDays] += t.amount;
        }
      }
    }
    return daily;
  }

  /// Monthly report data for selected report month
  double getReportIncomeForMonth(DateTime month) => getIncomeForMonth(month);
  double getReportExpenseForMonth(DateTime month) => getExpenseForMonth(month);

  Map<ExpenseCategory, double> getReportCategoriesForMonth(DateTime month) =>
      getCategoryExpensesForMonth(month);

  // ====================================================
  // DATABASE PERSISTENCE ACTIONS (SQLite Categories)
  // ====================================================

  /// Loads categories from SQLite database for the active user.
  Future<void> loadCategories([String? userId]) async {
    final targetUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : (_currentUserId.isNotEmpty ? _currentUserId : 'user_default');

    _currentUserId = targetUserId;

    try {
      _categories = await _dbHelper.getCategoriesByUserId(targetUserId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories from SQLite: $e');
    }
  }

  /// Checks if a category name already exists in SQLite.
  Future<bool> isCategoryNameExists(
    String name, {
    String? excludeId,
    TransactionType? type,
  }) async {
    final targetId = _currentUserId.isNotEmpty ? _currentUserId : 'user_default';
    return await _dbHelper.isCategoryNameExists(
      targetId,
      name,
      excludeId: excludeId,
      type: type,
    );
  }

  /// Checks how many transactions are using a category name.
  Future<int> checkCategoryUsage(String categoryName) async {
    final targetId = _currentUserId.isNotEmpty ? _currentUserId : 'user_default';
    return await _dbHelper.isCategoryUsedInTransactions(
      targetId,
      categoryName,
    );
  }

  /// Inserts a new Category into SQLite ensuring userId ownership.
  Future<bool> addCategory(CategoryModel category) async {
    final targetId = _currentUserId.isNotEmpty ? _currentUserId : 'user_default';
    _currentUserId = targetId;

    final exists = await isCategoryNameExists(
      category.name,
      type: category.type,
    );
    if (exists) return false;

    final secureCategory = category.copyWith(userId: targetId);
    await _dbHelper.insertCategory(secureCategory);
    await loadCategories(targetId);
    return true;
  }

  /// Updates an existing Category in SQLite.
  Future<bool> updateCategory(CategoryModel category) async {
    final targetId = _currentUserId.isNotEmpty ? _currentUserId : 'user_default';
    _currentUserId = targetId;

    final exists = await isCategoryNameExists(
      category.name,
      excludeId: category.id,
      type: category.type,
    );
    if (exists) return false;

    final secureCategory = category.copyWith(userId: targetId);
    await _dbHelper.updateCategory(secureCategory);
    await loadCategories(targetId);
    return true;
  }

  /// Deletes a Category from SQLite if not restricted.
  Future<bool> deleteCategory(dynamic id) async {
    final targetId = _currentUserId.isNotEmpty ? _currentUserId : 'user_default';
    await _dbHelper.deleteCategory(id, targetId);
    await loadCategories(targetId);
    return true;
  }

  // ====================================================
  // DATABASE PERSISTENCE ACTIONS (SQLite Transactions)
  // ====================================================

  /// Loads transactions from SQLite database for the current user.
  Future<void> loadTransactions([String? userId]) async {
    final targetUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : (_currentUserId.isNotEmpty ? _currentUserId : 'user_default');

    _currentUserId = targetUserId;
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbHelper.getTransactionsByUserId(targetUserId);
    } catch (e) {
      debugPrint('Error loading transactions from SQLite: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inserts a transaction into SQLite enforcing active user ID ownership.
  Future<void> addTransaction(TransactionModel transaction) async {
    final targetUserId = transaction.userId.isNotEmpty
        ? transaction.userId
        : (_currentUserId.isNotEmpty ? _currentUserId : 'user_default');

    _currentUserId = targetUserId;

    final secureTransaction = transaction.copyWith(userId: targetUserId);
    final insertedId = await _dbHelper.insertTransaction(secureTransaction);
    final savedTransaction = secureTransaction.copyWith(id: insertedId);

    _transactions.insert(0, savedTransaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// Updates an existing transaction in SQLite scoped to active user ID.
  Future<void> updateTransaction(TransactionModel transaction) async {
    final targetUserId = transaction.userId.isNotEmpty
        ? transaction.userId
        : (_currentUserId.isNotEmpty ? _currentUserId : 'user_default');

    _currentUserId = targetUserId;

    final secureTransaction = transaction.copyWith(userId: targetUserId);
    await _dbHelper.updateTransaction(secureTransaction);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = secureTransaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  /// Deletes a transaction from SQLite by ID scoped to active user ID.
  Future<void> deleteTransaction(dynamic id, [String? userId]) async {
    final targetUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : (_currentUserId.isNotEmpty ? _currentUserId : 'user_default');

    final parsedId = id is int ? id : int.tryParse(id.toString());
    final existingIndex = _transactions.indexWhere(
      (t) => t.id == parsedId || t.id.toString() == id.toString(),
    );
    if (existingIndex == -1) return;

    final removed = _transactions[existingIndex];
    _transactions.removeAt(existingIndex);
    notifyListeners();

    try {
      await _dbHelper.deleteTransaction(parsedId ?? id, targetUserId);
    } catch (e) {
      _transactions.insert(existingIndex, removed);
      notifyListeners();
      debugPrint('Error deleting transaction from SQLite: $e');
    }
  }

  // Compatibility helpers
  Future<void> loadExpenses() => loadTransactions();
  Future<void> addExpense(Expense expense) =>
      addTransaction(expense.toTransactionModel(_currentUserId));
  Future<void> deleteExpense(String id) => deleteTransaction(id, _currentUserId);
  Future<void> updateExpense(Expense expense) =>
      updateTransaction(expense.toTransactionModel(_currentUserId));

  void setFilter(TransactionFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setDateFilter(DateRangeFilter filter) {
    _currentDateFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryName) {
    _selectedCategoryFilter = categoryName;
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedReportMonth(DateTime month) {
    _selectedReportMonth = month;
    notifyListeners();
  }

  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }
}

/// Helper container for BarChart monthly values
class MonthlyBarData {
  final DateTime month;
  final double income;
  final double expense;

  const MonthlyBarData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

extension ExpenseConversion on Expense {
  TransactionModel toTransactionModel(String userId) {
    return TransactionModel(
      id: int.tryParse(id),
      userId: userId,
      title: title,
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      category: category.name,
      description: note ?? tag,
      date: date,
      createdAt: DateTime.now(),
    );
  }
}
