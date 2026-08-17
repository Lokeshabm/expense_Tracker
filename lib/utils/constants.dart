import 'package:flutter/material.dart';

/// Data structure representing a currency item with code, symbol, and full name.
class CurrencyItem {
  final String code;
  final String symbol;
  final String name;

  const CurrencyItem({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

/// Application constants including styling metrics, color palettes, and default settings.
class AppConstants {
  // App Info
  static const String appName = 'Expense Tracker';
  static const String appVersion = '1.0.0';

  // Currency Defaults
  static const String defaultCurrencySymbol = '\$';
  static const String defaultCurrencyCode = 'USD';

  // Supported Currency List
  static const List<CurrencyItem> supportedCurrencies = [
    CurrencyItem(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyItem(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyItem(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyItem(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyItem(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyItem(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
    CurrencyItem(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    CurrencyItem(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    CurrencyItem(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
    CurrencyItem(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal'),
    CurrencyItem(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    CurrencyItem(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
  ];

  // UI Spacing & Radius
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 999.0;

  // Animation Durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 350);
}

/// Custom Brand & Utility Colors
class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF1E88E5); // Modern Indigo/Blue
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Financial Semantics
  static const Color incomeGreen = Color(0xFF2E7D32);
  static const Color incomeGreenLight = Color(0xFFE8F5E9);
  static const Color expenseRed = Color(0xFFC62828);
  static const Color expenseRedLight = Color(0xFFFFEBEE);

  // Neutral Colors
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1C1B1F);
  static const Color textSecondaryLight = Color(0xFF757575);

  static const Color surfaceDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE6E1E5);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
}
