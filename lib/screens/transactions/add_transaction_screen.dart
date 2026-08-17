import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/date_picker_tile.dart';
import '../../widgets/transaction_type_toggle.dart';

/// Screen allowing users to add a new transaction or edit an existing one,
/// saving the record directly into the local SQLite database.
class AddTransactionScreen extends StatefulWidget {
  final bool initialIsIncome;
  final Expense? existingExpense;

  const AddTransactionScreen({
    super.key,
    this.initialIsIncome = false,
    this.existingExpense,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late TransactionType _selectedType;
  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingExpense;
    _selectedType = item != null
        ? (item.isIncome ? TransactionType.income : TransactionType.expense)
        : (widget.initialIsIncome
            ? TransactionType.income
            : TransactionType.expense);

    _titleController = TextEditingController(text: item?.title ?? '');
    _amountController = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(2) : '',
    );
    _descriptionController =
        TextEditingController(text: item?.note ?? item?.tag ?? '');
    _selectedDate = item?.date ?? DateTime.now();

    if (item != null) {
      _selectedCategory = item.category;
    } else {
      _selectedCategory = _selectedType == TransactionType.income
          ? ExpenseCategory.salary
          : ExpenseCategory.food;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Changes transaction type and resets the selected category to a matching default.
  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      if (type == TransactionType.income) {
        _selectedCategory = ExpenseCategory.salary;
      } else {
        _selectedCategory = ExpenseCategory.food;
      }
    });
  }

  /// Handles form validation, constructs the TransactionModel, and persists it into SQLite.
  Future<void> _handleSaveTransaction() async {
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final cleanTitle = _titleController.text.trim();
    final cleanAmountStr = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(cleanAmountStr);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: AppColors.expenseRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    // Retrieve active user ID
    final currentUserId = authProvider.userId.isNotEmpty
        ? authProvider.userId
        : (expenseProvider.currentUserId.isNotEmpty
            ? expenseProvider.currentUserId
            : 'user_default');

    expenseProvider.setCurrentUserId(currentUserId);

    try {
      if (widget.existingExpense != null) {
        // Update existing transaction in SQLite
        final updatedTransaction = TransactionModel(
          id: int.tryParse(widget.existingExpense!.id),
          userId: currentUserId,
          title: cleanTitle,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory.name,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _selectedDate,
          createdAt: DateTime.now(),
        );

        await expenseProvider.updateTransaction(updatedTransaction);
      } else {
        // Insert new transaction into SQLite (SQLite AUTOINCREMENT assigns integer primary key)
        final newTransaction = TransactionModel(
          id: null,
          userId: currentUserId,
          title: cleanTitle,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory.name,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _selectedDate,
          createdAt: DateTime.now(),
        );

        await expenseProvider.addTransaction(newTransaction);
      }

      if (!mounted) return;

      // Show success feedback message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedType.isIncome ? "Income" : "Expense"} "$cleanTitle" saved successfully!',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.incomeGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Return to Dashboard
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save transaction: $e'),
          backgroundColor: AppColors.expenseRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingExpense != null ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSaveTransaction,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.paddingMedium,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Transaction Type Toggle (Income / Expense)
                TransactionTypeToggle(
                  selectedType: _selectedType,
                  onTypeChanged: _onTypeChanged,
                ),
                const SizedBox(height: 20),

                // 2. Amount Input Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: _selectedType.isIncome
                                ? AppColors.incomeGreen
                                : (_selectedType.isExpense
                                    ? AppColors.expenseRed
                                    : (isDark ? Colors.white : Colors.black87)),
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                expenseProvider.currencySymbol,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 0, minHeight: 0),
                            hintText: '0.00',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an amount';
                            }
                            final cleanVal = value.trim().replaceAll(',', '');
                            final val = double.tryParse(cleanVal);
                            if (val == null || val <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Title Input Field
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Title',
                  hintText: _selectedType.isIncome
                      ? 'e.g., Monthly Salary, Freelance project'
                      : 'e.g., Whole Foods Grocery, Electricity Bill',
                  prefixIcon: Icons.edit_note_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 4. Category Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: CategorySelector(
                      transactionType: _selectedType,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (cat) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Transaction Date Picker
                DatePickerTile(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 6. Description / Notes Field
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description (Optional)',
                  hintText: 'Add notes, tags, or reference memo...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // 7. Save / Submit Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSaveTransaction,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.existingExpense != null
                              ? 'Update Transaction'
                              : (_selectedType.isIncome
                                  ? 'Save Income'
                                  : 'Save Expense'),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
