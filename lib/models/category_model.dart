import 'package:flutter/material.dart';
import 'transaction_model.dart';

/// Data Model representing a Custom or Predefined Category in SQLite.
class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final TransactionType type;
  final String icon; // Stores icon codePoint string or icon key
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.createdAt,
  });

  /// Helper getter to check if it's an income category
  bool get isIncome => type == TransactionType.income;

  /// Helper getter to check if it's an expense category
  bool get isExpense => type == TransactionType.expense;

  /// Converts the category icon string into Flutter's IconData safely.
  IconData get iconData {
    final intCodePoint = int.tryParse(icon);
    if (intCodePoint != null) {
      // ignore: non_const_argument_for_const_parameter
      return IconData(intCodePoint, fontFamily: 'MaterialIcons');
    }
    return _getNamedIcon(icon);
  }

  /// Maps string names to IconData fallback
  static IconData _getNamedIcon(String name) {
    switch (name.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'transport':
      case 'car':
        return Icons.directions_car_rounded;
      case 'bills':
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'entertainment':
      case 'movie':
        return Icons.movie_rounded;
      case 'health':
      case 'medical':
        return Icons.medical_services_rounded;
      case 'education':
      case 'school':
        return Icons.school_rounded;
      case 'salary':
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'business':
      case 'store':
        return Icons.storefront_rounded;
      case 'freelance':
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'investment':
      case 'trending':
        return Icons.trending_up_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  /// Creates a copy of CategoryModel with modified properties
  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    TransactionType? type,
    String? icon,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts CategoryModel to a Map for SQLite storage.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'name': name,
      'type': type.value,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };

    if (id.isNotEmpty) {
      final intId = int.tryParse(id);
      if (intId != null) {
        map['id'] = intId;
      } else {
        map['id'] = id;
      }
    }
    return map;
  }

  /// Factory constructor to reconstruct a CategoryModel from SQLite row map.
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: TransactionType.fromString(map['type']?.toString()),
      icon: map['icon']?.toString() ?? Icons.category_rounded.codePoint.toString(),
      createdAt: _parseDateTime(map['createdAt'] ?? map['created_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name.toLowerCase() == other.name.toLowerCase() &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ name.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'CategoryModel(id: $id, userId: $userId, name: $name, type: ${type.value})';
  }
}
