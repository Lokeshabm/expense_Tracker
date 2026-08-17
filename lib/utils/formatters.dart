import 'package:intl/intl.dart';
import 'constants.dart';

/// Helper utility for formatting currencies, numbers, and dates cleanly across the app.
class Formatters {
  /// Formats amount into standard currency representation (e.g. $1,250.00)
  static String formatCurrency(double amount, {String? symbol}) {
    final formatter = NumberFormat.currency(
      symbol: symbol ?? AppConstants.defaultCurrencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Formats amount without decimals if it's a whole number (e.g. $1,250)
  static String formatCurrencyCompact(double amount, {String? symbol}) {
    final formatter = NumberFormat.compactCurrency(
      symbol: symbol ?? AppConstants.defaultCurrencySymbol,
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }

  /// Compact currency helper (alias for formatCurrencyCompact)
  static String formatCompactCurrency(double amount, {String? symbol}) {
    return formatCurrencyCompact(amount, symbol: symbol);
  }

  /// Formats a DateTime into a readable string (e.g., "Aug 15, 2026")
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Formats a DateTime into short date format (e.g., "15/08/2026")
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formats a DateTime with a relative time indicator (e.g., "Today", "Yesterday", or "Aug 15")
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (checkDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (now.year == date.year) {
      return DateFormat('MMM dd • h:mm a').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
