import 'package:flutter/material.dart';

/// Represents a Category for an Expense or Income transaction.
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncomeCategory;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isIncomeCategory = false,
  });

  // Predefined Expense Categories
  static const ExpenseCategory food = ExpenseCategory(
    id: 'food',
    name: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFF7043),
  );

  static const ExpenseCategory shopping = ExpenseCategory(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFAB47BC),
  );

  static const ExpenseCategory transport = ExpenseCategory(
    id: 'transport',
    name: 'Transport',
    icon: Icons.directions_car_rounded,
    color: Color(0xFF29B6F6),
  );

  static const ExpenseCategory bills = ExpenseCategory(
    id: 'bills',
    name: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFFFA726),
  );

  static const ExpenseCategory entertainment = ExpenseCategory(
    id: 'entertainment',
    name: 'Entertainment',
    icon: Icons.movie_rounded,
    color: Color(0xFFEC407A),
  );

  static const ExpenseCategory health = ExpenseCategory(
    id: 'health',
    name: 'Health',
    icon: Icons.medical_services_rounded,
    color: Color(0xFF26A69A),
  );

  static const ExpenseCategory education = ExpenseCategory(
    id: 'education',
    name: 'Education',
    icon: Icons.school_rounded,
    color: Color(0xFF5C6BC0),
  );

  static const ExpenseCategory otherExpense = ExpenseCategory(
    id: 'other_expense',
    name: 'Other',
    icon: Icons.category_rounded,
    color: Color(0xFF78909C),
  );

  // Predefined Income Categories
  static const ExpenseCategory salary = ExpenseCategory(
    id: 'salary',
    name: 'Salary',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF4CAF50),
    isIncomeCategory: true,
  );

  static const ExpenseCategory business = ExpenseCategory(
    id: 'business',
    name: 'Business',
    icon: Icons.storefront_rounded,
    color: Color(0xFF00ACC1),
    isIncomeCategory: true,
  );

  static const ExpenseCategory freelance = ExpenseCategory(
    id: 'freelance',
    name: 'Freelance',
    icon: Icons.laptop_mac_rounded,
    color: Color(0xFF66BB6A),
    isIncomeCategory: true,
  );

  static const ExpenseCategory investment = ExpenseCategory(
    id: 'investment',
    name: 'Investment',
    icon: Icons.trending_up_rounded,
    color: Color(0xFF00897B),
    isIncomeCategory: true,
  );

  static const ExpenseCategory gift = ExpenseCategory(
    id: 'gift',
    name: 'Gift',
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFF8E24AA),
    isIncomeCategory: true,
  );

  static const ExpenseCategory otherIncome = ExpenseCategory(
    id: 'other_income',
    name: 'Other',
    icon: Icons.savings_rounded,
    color: Color(0xFF43A047),
    isIncomeCategory: true,
  );

  // Aliases for compatibility
  static const ExpenseCategory transportation = transport;
  static const ExpenseCategory investments = investment;
  static const ExpenseCategory gifts = gift;
  static const ExpenseCategory other = otherExpense;

  /// Default list of all categories available in the app
  static const List<ExpenseCategory> defaultCategories = [
    food,
    shopping,
    transport,
    bills,
    entertainment,
    health,
    education,
    otherExpense,
    salary,
    business,
    freelance,
    investment,
    gift,
    otherIncome,
  ];

  static List<ExpenseCategory> get expenseCategories => [
        food,
        shopping,
        transport,
        bills,
        entertainment,
        health,
        education,
        otherExpense,
      ];

  static List<ExpenseCategory> get incomeCategories => [
        salary,
        business,
        freelance,
        investment,
        gift,
        otherIncome,
      ];

  /// Find category by its name or ID
  static ExpenseCategory fromName(String name, {bool isIncome = false}) {
    final lowerName = name.toLowerCase().trim();
    for (final cat in defaultCategories) {
      if (cat.name.toLowerCase() == lowerName ||
          cat.id.toLowerCase() == lowerName) {
        return cat;
      }
    }
    return isIncome ? otherIncome : otherExpense;
  }

  /// Find category by its ID
  static ExpenseCategory fromId(String id) {
    return fromName(id);
  }
}
