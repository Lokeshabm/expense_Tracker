import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'category_chip.dart';

/// Modal bottom sheet allowing users to create a new expense or income transaction.
class AddExpenseBottomSheet extends StatefulWidget {
  const AddExpenseBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddExpenseBottomSheet(),
    );
  }

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncome = false;
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitData() {
    if (!_formKey.currentState!.validate()) return;

    final enteredTitle = _titleController.text.trim();
    final enteredAmount = double.tryParse(_amountController.text.trim());

    if (enteredAmount == null || enteredAmount <= 0) return;

    final newExpense = Expense(
      id: const Uuid().v4(),
      title: enteredTitle,
      amount: enteredAmount,
      date: _selectedDate,
      category: _selectedCategory,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      isIncome: _isIncome,
    );

    Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_isIncome ? "Income" : "Expense"} "$enteredTitle" added successfully!',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppConstants.paddingLarge,
        right: AppConstants.paddingLarge,
        top: AppConstants.paddingMedium,
        bottom: keyboardSpace + AppConstants.paddingLarge,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Transaction',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Income / Expense Type Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isIncome = false;
                          if (_selectedCategory == ExpenseCategory.salary) {
                            _selectedCategory = ExpenseCategory.food;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isIncome
                              ? (isDark ? AppColors.cardDark : Colors.white)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSmall),
                          boxShadow: !_isIncome
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: !_isIncome
                                  ? AppColors.expenseRed
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Expense',
                              style: TextStyle(
                                fontWeight: !_isIncome
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: !_isIncome
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isIncome = true;
                          _selectedCategory = ExpenseCategory.salary;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isIncome
                              ? (isDark ? AppColors.cardDark : Colors.white)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSmall),
                          boxShadow: _isIncome
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: _isIncome
                                  ? AppColors.incomeGreen
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Income',
                              style: TextStyle(
                                fontWeight: _isIncome
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _isIncome
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppConstants.defaultCurrencySymbol,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0.00',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final numVal = double.tryParse(value.trim());
                if (numVal == null || numVal <= 0) {
                  return 'Enter a valid amount greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Title Input
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title / Description',
                hintText: 'e.g., Grocery Shopping, Salary',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Category Section
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ExpenseCategory.defaultCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = ExpenseCategory.defaultCategories[index];
                  return CategoryChip(
                    category: category,
                    isSelected: _selectedCategory.id == category.id,
                    onSelected: (cat) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Date Picker Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha(40)
                              : Colors.grey.withAlpha(60),
                        ),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              Text(
                                Formatters.formatDate(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Note input (Optional)
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Additional details or memo...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Submit Button
            ElevatedButton(
              onPressed: _submitData,
              child: Text(
                _isIncome ? 'Add Income' : 'Add Expense',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
