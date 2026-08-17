/// Supported Transaction Types in the application.
enum TransactionType {
  income,
  expense;

  /// String value representation (e.g. 'income', 'expense').
  String get value => name;

  /// Helper getter for checking if the transaction is income.
  bool get isIncome => this == TransactionType.income;

  /// Helper getter for checking if the transaction is an expense.
  bool get isExpense => this == TransactionType.expense;

  /// Parses a string or integer value safely into a TransactionType.
  static TransactionType fromString(String? type) {
    if (type == null) return TransactionType.expense;
    final normalized = type.trim().toLowerCase();
    if (normalized == 'income' || normalized == '1') {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }
}

/// Data Model representing an Income or Expense Transaction.
/// Uses an auto-incrementing integer ID for SQLite compatibility.
class TransactionModel {
  final int? id;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  const TransactionModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    required this.createdAt,
  });

  /// Creates a copy of this TransactionModel with optional replacement values.
  TransactionModel copyWith({
    int? id,
    String? userId,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts the TransactionModel to a `Map<String, dynamic>` formatted for SQLite storage.
  /// Omits `id` when null so SQLite automatically generates AUTOINCREMENT primary key.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type.value,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Factory constructor to reconstruct a TransactionModel safely from a Map (e.g., from SQLite query result).
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: _parseAmount(map['amount']),
      type: TransactionType.fromString(map['type']?.toString()),
      category: map['category']?.toString() ?? 'Other',
      description: map['description']?.toString(),
      date: _parseDateTime(map['date']),
      createdAt: _parseDateTime(map['createdAt'] ?? map['created_at']),
    );
  }

  /// Safely parses monetary amount into double regardless of integer, num, or string format.
  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Safely parses DateTime from ISO-8601 string, integer timestamp (milliseconds), or falls back to DateTime.now().
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final intTimestamp = int.tryParse(value);
      if (intTimestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(intTimestamp);
      }
    }
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          amount == other.amount &&
          type == other.type &&
          category == other.category &&
          description == other.description &&
          date == other.date &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      amount.hashCode ^
      type.hashCode ^
      category.hashCode ^
      description.hashCode ^
      date.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'TransactionModel(id: $id, userId: $userId, title: $title, amount: $amount, type: ${type.value}, category: $category, date: $date)';
  }
}
