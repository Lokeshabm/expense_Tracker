import '../models/expense.dart';
import '../models/category.dart';

/// Abstract service layer interface defining operations on Expense data.
abstract class ExpenseService {
  Future<List<Expense>> getExpenses();
  Future<void> addExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<void> updateExpense(Expense expense);
}

/// In-memory implementation of ExpenseService with rich initial mock data.
class InMemoryExpenseService implements ExpenseService {
  static final DateTime _now = DateTime.now();

  final List<Expense> _expenses = [
    Expense(
      id: '1',
      title: 'Monthly Salary',
      amount: 4800.00,
      date: DateTime(_now.year, _now.month, 1, 9, 0),
      category: ExpenseCategory.salary,
      note: 'Monthly salary from Tech Corp',
      isIncome: true,
      paymentMethod: PaymentMethod.bankTransfer,
      tag: 'Work',
    ),
    Expense(
      id: '2',
      title: 'Freelance UI Design',
      amount: 650.00,
      date: DateTime(_now.year, _now.month, 5, 14, 30),
      category: ExpenseCategory.freelance,
      note: 'Landing page design for client',
      isIncome: true,
      paymentMethod: PaymentMethod.digitalWallet,
      tag: 'Side Gig',
    ),
    Expense(
      id: '3',
      title: 'Whole Foods Market',
      amount: 142.50,
      date: DateTime(_now.year, _now.month, _now.day, 12, 15),
      category: ExpenseCategory.food,
      note: 'Weekly organic groceries & fruits',
      isIncome: false,
      paymentMethod: PaymentMethod.creditCard,
      tag: 'Groceries',
    ),
    Expense(
      id: '4',
      title: 'Electric & Power Bill',
      amount: 92.40,
      date: DateTime(_now.year, _now.month, _now.day > 1 ? _now.day - 1 : 1, 16, 45),
      category: ExpenseCategory.bills,
      note: 'Monthly power utility bill',
      isIncome: false,
      paymentMethod: PaymentMethod.bankTransfer,
      tag: 'Utilities',
    ),
    Expense(
      id: '5',
      title: 'Coffee & Breakfast',
      amount: 14.80,
      date: DateTime(_now.year, _now.month, _now.day, 8, 30),
      category: ExpenseCategory.food,
      note: 'Latte & croissant at artisan bakery',
      isIncome: false,
      paymentMethod: PaymentMethod.digitalWallet,
      tag: 'Dining',
    ),
    Expense(
      id: '6',
      title: 'Zara Clothing Store',
      amount: 185.00,
      date: DateTime(_now.year, _now.month, _now.day > 2 ? _now.day - 2 : 1, 17, 20),
      category: ExpenseCategory.shopping,
      note: 'Autumn jacket and shirts',
      isIncome: false,
      paymentMethod: PaymentMethod.creditCard,
      tag: 'Fashion',
    ),
    Expense(
      id: '7',
      title: 'Gas Station Fuel',
      amount: 58.00,
      date: DateTime(_now.year, _now.month, _now.day > 3 ? _now.day - 3 : 1, 10, 10),
      category: ExpenseCategory.transportation,
      note: 'Full tank premium gasoline',
      isIncome: false,
      paymentMethod: PaymentMethod.creditCard,
      tag: 'Car',
    ),
    Expense(
      id: '8',
      title: 'Cinema & Popcorn',
      amount: 38.50,
      date: DateTime(_now.year, _now.month, _now.day > 4 ? _now.day - 4 : 1, 20, 0),
      category: ExpenseCategory.entertainment,
      note: 'IMAX weekend movie night',
      isIncome: false,
      paymentMethod: PaymentMethod.cash,
      tag: 'Leisure',
    ),
    Expense(
      id: '9',
      title: 'Pharmacy & Vitamins',
      amount: 45.20,
      date: DateTime(_now.year, _now.month, _now.day > 5 ? _now.day - 5 : 1, 11, 40),
      category: ExpenseCategory.health,
      note: 'Multivitamins & prescription',
      isIncome: false,
      paymentMethod: PaymentMethod.debitCard,
      tag: 'Health',
    ),
    Expense(
      id: '10',
      title: 'Stock Dividend',
      amount: 120.00,
      date: DateTime(_now.year, _now.month, 8, 9, 15),
      category: ExpenseCategory.investments,
      note: 'Quarterly dividend payout',
      isIncome: true,
      paymentMethod: PaymentMethod.bankTransfer,
      tag: 'Investments',
    ),
    Expense(
      id: '11',
      title: 'Online Course Subscription',
      amount: 29.99,
      date: DateTime(_now.year, _now.month, 10, 15, 0),
      category: ExpenseCategory.education,
      note: 'Flutter Advanced Masterclass',
      isIncome: false,
      paymentMethod: PaymentMethod.creditCard,
      tag: 'Learning',
    ),
  ];

  @override
  Future<List<Expense>> getExpenses() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List<Expense>.from(_expenses);
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 30));
    _expenses.insert(0, expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await Future.delayed(const Duration(milliseconds: 30));
    _expenses.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
    }
  }
}
