import 'category.dart';

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  digitalWallet;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
    }
  }
}

/// Represents a single transaction (Expense or Income) in the application.
class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? note;
  final bool isIncome;
  final PaymentMethod paymentMethod;
  final String? tag;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
    this.isIncome = false,
    this.paymentMethod = PaymentMethod.creditCard,
    this.tag,
  });

  /// Create a copy of this expense with optional modified fields
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? note,
    bool? isIncome,
    PaymentMethod? paymentMethod,
    String? tag,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      isIncome: isIncome ?? this.isIncome,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tag: tag ?? this.tag,
    );
  }

  /// Converts the Expense object to a Map for database storage (e.g. SQLite/Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': category.id,
      'note': note,
      'is_income': isIncome ? 1 : 0,
      'payment_method': paymentMethod.name,
      'tag': tag,
    };
  }

  /// Factory constructor to reconstruct an Expense from a Map (e.g., from SQLite row)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: ExpenseCategory.fromId(map['category_id'] as String),
      note: map['note'] as String?,
      isIncome: (map['is_income'] as int) == 1,
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (p) => p.name == map['payment_method'],
              orElse: () => PaymentMethod.cash,
            )
          : PaymentMethod.cash,
      tag: map['tag'] as String?,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, isIncome: $isIncome, date: $date)';
  }
}
