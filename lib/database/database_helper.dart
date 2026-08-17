import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// DatabaseHelper manages all local SQLite database operations using `sqflite`.
/// Enforces strict user data isolation, parameterized queries for SQL injection prevention,
/// and safe transaction mutations scoped to the authenticated user ID.
class DatabaseHelper {
  // Singleton pattern instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Database Configuration
  static const String _databaseName = 'expense_tracker.db';
  static const int _databaseVersion = 3;

  // Table Names
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';

  // Transaction Column Names
  static const String columnId = 'id';
  static const String columnUserId = 'userId';
  static const String columnTitle = 'title';
  static const String columnAmount = 'amount';
  static const String columnType = 'type';
  static const String columnCategory = 'category';
  static const String columnDescription = 'description';
  static const String columnDate = 'date';
  static const String columnCreatedAt = 'createdAt';

  // Category Column Names
  static const String columnCategoryName = 'name';
  static const String columnCategoryIcon = 'icon';

  /// Lazy database getter: initializes the database on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the SQLite database file in the platform's standard database directory.
  Future<Database> _initDatabase() async {
    // Ensure databaseFactory is initialized on desktop platforms (Windows, Linux, macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates database tables upon initial creation.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Transactions Table with Primary Key & User Index
    await db.execute('''
      CREATE TABLE $tableTransactions (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserId TEXT NOT NULL,
        $columnTitle TEXT NOT NULL,
        $columnAmount REAL NOT NULL,
        $columnType TEXT NOT NULL,
        $columnCategory TEXT NOT NULL,
        $columnDescription TEXT,
        $columnDate TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');

    // Index for fast user-scoped query isolation
    await db.execute('''
      CREATE INDEX idx_transactions_user_date 
      ON $tableTransactions ($columnUserId, $columnDate DESC)
    ''');

    // 2. Categories Table
    await db.execute('''
      CREATE TABLE $tableCategories (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserId TEXT NOT NULL,
        $columnCategoryName TEXT NOT NULL,
        $columnType TEXT NOT NULL,
        $columnCategoryIcon TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');

    // Index on userId and category name
    await db.execute('''
      CREATE INDEX idx_categories_user_name 
      ON $tableCategories ($columnUserId, $columnCategoryName)
    ''');
  }

  /// Handles database schema updates across versions safely.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableCategories (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnUserId TEXT NOT NULL,
          $columnCategoryName TEXT NOT NULL,
          $columnType TEXT NOT NULL,
          $columnCategoryIcon TEXT NOT NULL,
          $columnCreatedAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_categories_user_name 
        ON $tableCategories ($columnUserId, $columnCategoryName)
      ''');
    }

    if (oldVersion < 3) {
      // Safe development migration to resolve datatype mismatches on transactions table
      await db.execute('DROP TABLE IF EXISTS $tableTransactions');
      await db.execute('''
        CREATE TABLE $tableTransactions (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnUserId TEXT NOT NULL,
          $columnTitle TEXT NOT NULL,
          $columnAmount REAL NOT NULL,
          $columnType TEXT NOT NULL,
          $columnCategory TEXT NOT NULL,
          $columnDescription TEXT,
          $columnDate TEXT NOT NULL,
          $columnCreatedAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_user_date 
        ON $tableTransactions ($columnUserId, $columnDate DESC)
      ''');
    }
  }

  // ==========================================
  // TRANSACTIONS OPERATIONS (STRICT USER ISOLATION)
  // ==========================================

  /// Inserts a new transaction using db.insert(), letting SQLite assign the AUTOINCREMENT id.
  Future<int> insertTransaction(TransactionModel transaction) async {
    if (transaction.userId.trim().isEmpty) {
      throw ArgumentError('Security Error: Cannot insert transaction without a valid user ID.');
    }
    if (transaction.amount <= 0) {
      throw ArgumentError('Validation Error: Transaction amount must be strictly greater than 0.');
    }

    final db = await instance.database;
    final map = transaction.toMap();

    // Use standard db.insert - SQLite auto-generates the integer primary key
    return await db.insert(
      tableTransactions,
      map,
    );
  }

  /// Retrieves all transactions belonging strictly to the authenticated user ID.
  Future<List<TransactionModel>> getTransactionsByUserId(String userId) async {
    if (userId.trim().isEmpty) return [];

    final db = await instance.database;
    final result = await db.query(
      tableTransactions,
      where: '$columnUserId = ?',
      whereArgs: [userId.trim()],
      orderBy: '$columnDate DESC, $columnId DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Retrieves a single transaction by its primary key ID scoped to the specified user ID.
  Future<TransactionModel?> getTransactionById(dynamic id, String userId) async {
    if (userId.trim().isEmpty) return null;

    final db = await instance.database;
    final result = await db.query(
      tableTransactions,
      where: '$columnId = ? AND $columnUserId = ?',
      whereArgs: [id, userId.trim()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return TransactionModel.fromMap(result.first);
    }
    return null;
  }

  /// Updates an existing transaction ensuring user ID ownership matches.
  Future<int> updateTransaction(TransactionModel transaction) async {
    if (transaction.userId.trim().isEmpty) {
      throw ArgumentError('Security Error: Cannot update transaction without a valid user ID.');
    }

    final db = await instance.database;
    return await db.update(
      tableTransactions,
      transaction.toMap(),
      where: '$columnId = ? AND $columnUserId = ?',
      whereArgs: [transaction.id, transaction.userId.trim()],
    );
  }

  /// Deletes a transaction by ID scoped strictly to the owning user ID.
  Future<int> deleteTransaction(dynamic id, String userId) async {
    if (userId.trim().isEmpty) return 0;

    final db = await instance.database;
    return await db.delete(
      tableTransactions,
      where: '$columnId = ? AND $columnUserId = ?',
      whereArgs: [id, userId.trim()],
    );
  }

  /// Deletes all transactions associated with a user ID.
  Future<int> deleteTransactionsByUserId(String userId) async {
    if (userId.trim().isEmpty) return 0;

    final db = await instance.database;
    return await db.delete(
      tableTransactions,
      where: '$columnUserId = ?',
      whereArgs: [userId.trim()],
    );
  }

  /// Retrieves all income transactions for a specific user.
  Future<List<TransactionModel>> getIncomeTransactions(String userId) async {
    if (userId.trim().isEmpty) return [];

    final db = await instance.database;
    final result = await db.query(
      tableTransactions,
      where: '$columnUserId = ? AND $columnType = ?',
      whereArgs: [userId.trim(), TransactionType.income.value],
      orderBy: '$columnDate DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Retrieves all expense transactions for a specific user.
  Future<List<TransactionModel>> getExpenseTransactions(String userId) async {
    if (userId.trim().isEmpty) return [];

    final db = await instance.database;
    final result = await db.query(
      tableTransactions,
      where: '$columnUserId = ? AND $columnType = ?',
      whereArgs: [userId.trim(), TransactionType.expense.value],
      orderBy: '$columnDate DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Retrieves transactions for a user matching a specific year and month.
  Future<List<TransactionModel>> getTransactionsByMonth(
    String userId,
    int year,
    int month,
  ) async {
    if (userId.trim().isEmpty) return [];

    final db = await instance.database;
    final monthStr = month.toString().padLeft(2, '0');
    final monthPattern = '$year-$monthStr%';

    final result = await db.query(
      tableTransactions,
      where: '$columnUserId = ? AND $columnDate LIKE ?',
      whereArgs: [userId.trim(), monthPattern],
      orderBy: '$columnDate DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Calculates the sum of all income transactions for a user.
  Future<double> getTotalIncome(String userId) async {
    if (userId.trim().isEmpty) return 0.0;

    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM($columnAmount), 0.0) as total 
      FROM $tableTransactions 
      WHERE $columnUserId = ? AND $columnType = ?
      ''',
      [userId.trim(), TransactionType.income.value],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Calculates the sum of all expense transactions for a user.
  Future<double> getTotalExpenses(String userId) async {
    if (userId.trim().isEmpty) return 0.0;

    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM($columnAmount), 0.0) as total 
      FROM $tableTransactions 
      WHERE $columnUserId = ? AND $columnType = ?
      ''',
      [userId.trim(), TransactionType.expense.value],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Calculates total net balance (Total Income - Total Expenses) for a user.
  Future<double> getBalance(String userId) async {
    final totalIncome = await getTotalIncome(userId);
    final totalExpenses = await getTotalExpenses(userId);
    return totalIncome - totalExpenses;
  }

  // ==========================================
  // CATEGORIES OPERATIONS (STRICT USER ISOLATION)
  // ==========================================

  /// Inserts a new category into the SQLite `categories` table.
  Future<int> insertCategory(CategoryModel category) async {
    if (category.userId.trim().isEmpty) {
      throw ArgumentError('Security Error: Cannot insert category without a valid user ID.');
    }

    final db = await instance.database;
    final map = category.toMap();
    if (category.id.isEmpty) {
      map.remove(columnId);
    }
    return await db.insert(
      tableCategories,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all categories for a specific user from SQLite.
  Future<List<CategoryModel>> getCategoriesByUserId(String userId) async {
    if (userId.trim().isEmpty) return [];

    final db = await instance.database;
    final result = await db.query(
      tableCategories,
      where: '$columnUserId = ?',
      whereArgs: [userId.trim()],
      orderBy: '$columnType ASC, $columnCategoryName ASC',
    );

    // Seed default categories if none exist for this user yet
    if (result.isEmpty) {
      await seedDefaultCategories(userId.trim());
      final seededResult = await db.query(
        tableCategories,
        where: '$columnUserId = ?',
        whereArgs: [userId.trim()],
        orderBy: '$columnType ASC, $columnCategoryName ASC',
      );
      return seededResult.map((map) => CategoryModel.fromMap(map)).toList();
    }

    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  /// Updates an existing category in SQLite matching its ID and owning User ID.
  Future<int> updateCategory(CategoryModel category) async {
    if (category.userId.trim().isEmpty) {
      throw ArgumentError('Security Error: Cannot update category without a valid user ID.');
    }

    final db = await instance.database;
    return await db.update(
      tableCategories,
      category.toMap(),
      where: '$columnId = ? AND $columnUserId = ?',
      whereArgs: [category.id, category.userId.trim()],
    );
  }

  /// Deletes a category by ID scoped strictly to the owning User ID.
  Future<int> deleteCategory(dynamic id, String userId) async {
    if (userId.trim().isEmpty) return 0;

    final db = await instance.database;
    return await db.delete(
      tableCategories,
      where: '$columnId = ? AND $columnUserId = ?',
      whereArgs: [id, userId.trim()],
    );
  }

  /// Checks whether a category with the same name already exists for a user (case-insensitive).
  Future<bool> isCategoryNameExists(
    String userId,
    String name, {
    String? excludeId,
    TransactionType? type,
  }) async {
    if (userId.trim().isEmpty) return false;

    final db = await instance.database;
    String whereClause = '$columnUserId = ? AND LOWER($columnCategoryName) = ?';
    List<dynamic> whereArgs = [userId.trim(), name.trim().toLowerCase()];

    if (type != null) {
      whereClause += ' AND $columnType = ?';
      whereArgs.add(type.value);
    }

    if (excludeId != null && excludeId.isNotEmpty) {
      whereClause += ' AND $columnId != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      tableCategories,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Checks how many transactions in SQLite are currently using a specific category name.
  Future<int> isCategoryUsedInTransactions(
    String userId,
    String categoryName,
  ) async {
    if (userId.trim().isEmpty) return 0;

    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM $tableTransactions 
      WHERE $columnUserId = ? AND LOWER($columnCategory) = ?
      ''',
      [userId.trim(), categoryName.trim().toLowerCase()],
    );

    if (result.isNotEmpty && result.first['count'] != null) {
      return (result.first['count'] as num).toInt();
    }
    return 0;
  }

  /// Seeds standard default Expense and Income categories into SQLite for a new user.
  Future<void> seedDefaultCategories(String userId) async {
    if (userId.trim().isEmpty) return;

    final db = await instance.database;
    final now = DateTime.now();

    final defaultExpenseCategories = [
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Food',
        type: TransactionType.expense,
        icon: Icons.restaurant_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Shopping',
        type: TransactionType.expense,
        icon: Icons.shopping_bag_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Transport',
        type: TransactionType.expense,
        icon: Icons.directions_car_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Bills',
        type: TransactionType.expense,
        icon: Icons.receipt_long_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Entertainment',
        type: TransactionType.expense,
        icon: Icons.movie_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Health',
        type: TransactionType.expense,
        icon: Icons.medical_services_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Education',
        type: TransactionType.expense,
        icon: Icons.school_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Other',
        type: TransactionType.expense,
        icon: Icons.category_rounded.codePoint.toString(),
        createdAt: now,
      ),
    ];

    final defaultIncomeCategories = [
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Salary',
        type: TransactionType.income,
        icon: Icons.account_balance_wallet_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Business',
        type: TransactionType.income,
        icon: Icons.storefront_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Freelance',
        type: TransactionType.income,
        icon: Icons.laptop_mac_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Investment',
        type: TransactionType.income,
        icon: Icons.trending_up_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Gift',
        type: TransactionType.income,
        icon: Icons.card_giftcard_rounded.codePoint.toString(),
        createdAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Other',
        type: TransactionType.income,
        icon: Icons.savings_rounded.codePoint.toString(),
        createdAt: now,
      ),
    ];

    for (final category in [
      ...defaultExpenseCategories,
      ...defaultIncomeCategories
    ]) {
      final map = category.toMap();
      map.remove(columnId);
      await db.insert(
        tableCategories,
        map,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Closes database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
