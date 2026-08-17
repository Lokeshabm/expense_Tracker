import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';

/// Screen allowing users to view, create, edit, and delete custom expense & income categories.
/// Integrated directly with SQLite database via ExpenseProvider.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Available icons for selection in Category dialog
  static const List<IconData> _availableIcons = [
    Icons.restaurant_rounded,
    Icons.shopping_bag_rounded,
    Icons.directions_car_rounded,
    Icons.receipt_long_rounded,
    Icons.movie_rounded,
    Icons.medical_services_rounded,
    Icons.school_rounded,
    Icons.category_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.storefront_rounded,
    Icons.laptop_mac_rounded,
    Icons.trending_up_rounded,
    Icons.card_giftcard_rounded,
    Icons.savings_rounded,
    Icons.flight_takeoff_rounded,
    Icons.fitness_center_rounded,
    Icons.local_cafe_rounded,
    Icons.pets_rounded,
    Icons.home_rounded,
    Icons.phone_android_rounded,
    Icons.fastfood_rounded,
    Icons.local_gas_station_rounded,
    Icons.build_rounded,
    Icons.payments_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Opens the Add or Edit Category dialog.
  void _showCategoryDialog(BuildContext context, {CategoryModel? categoryToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    TransactionType selectedType = categoryToEdit?.type ??
        (_tabController.index == 0
            ? TransactionType.expense
            : TransactionType.income);
    IconData selectedIcon = categoryToEdit != null
        ? categoryToEdit.iconData
        : (selectedType == TransactionType.expense
            ? Icons.category_rounded
            : Icons.savings_rounded);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              title: Text(
                categoryToEdit != null ? 'Edit Category' : 'Add New Category',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Switcher (Expense / Income)
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Expense'),
                              selected: selectedType == TransactionType.expense,
                              selectedColor: AppColors.expenseRed.withAlpha(40),
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() {
                                    selectedType = TransactionType.expense;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Income'),
                              selected: selectedType == TransactionType.income,
                              selectedColor: AppColors.incomeGreen.withAlpha(40),
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() {
                                    selectedType = TransactionType.income;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name Input Field
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g., Groceries, Freelance',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Category name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Icon Picker Selection
                      Text(
                        'Select Icon',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 160,
                        width: double.maxFinite,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(10)
                              : Colors.grey.withAlpha(20),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _availableIcons.length,
                          itemBuilder: (context, index) {
                            final icon = _availableIcons[index];
                            final isSelected =
                                selectedIcon.codePoint == icon.codePoint;

                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedIcon = icon;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: AppConstants.animationDurationShort,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withAlpha(50)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[700]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final name = nameController.text.trim();
                    final provider =
                        Provider.of<ExpenseProvider>(context, listen: false);
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final userId =
                        authProvider.user?.uid ?? provider.currentUserId;

                    // 7. Check for duplicate category name in SQLite
                    final isDuplicate = await provider.isCategoryNameExists(
                      name,
                      excludeId: categoryToEdit?.id,
                      type: selectedType,
                    );

                    if (isDuplicate) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'A ${selectedType.name} category named "$name" already exists.',
                          ),
                          backgroundColor: AppColors.expenseRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (categoryToEdit != null) {
                      // Update Category
                      final updated = categoryToEdit.copyWith(
                        name: name,
                        type: selectedType,
                        icon: selectedIcon.codePoint.toString(),
                      );
                      await provider.updateCategory(updated);
                    } else {
                      // Create New Category
                      final newCategory = CategoryModel(
                        id: const Uuid().v4(),
                        userId: userId,
                        name: name,
                        type: selectedType,
                        icon: selectedIcon.codePoint.toString(),
                        createdAt: DateTime.now(),
                      );
                      await provider.addCategory(newCategory);
                    }

                    if (!context.mounted) return;
                    Navigator.of(ctx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          categoryToEdit != null
                              ? 'Category "$name" updated!'
                              : 'Category "$name" created!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(categoryToEdit != null ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Deletes a category or shows warning if used in transactions.
  Future<void> _handleDeleteCategory(
      BuildContext context, ExpenseProvider provider, CategoryModel category) async {
    // 8. Prevent deletion if category is currently used by transactions in SQLite
    final usageCount = await provider.checkCategoryUsage(category.name);

    if (!context.mounted) return;

    if (usageCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed),
              SizedBox(width: 8),
              Text('Cannot Delete Category'),
            ],
          ),
          content: Text(
            'The category "${category.name}" is currently being used by $usageCount transaction(s).\n\nPlease delete or edit those transactions before removing this category.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmation Dialog before deletion
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.deleteCategory(category.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.name}" deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final expenseCats = provider.expenseCategoriesModels;
        final incomeCats = provider.incomeCategoriesModels;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Manage Categories',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(context, provider, expenseCats),
              _buildCategoryList(context, provider, incomeCats),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'categories_fab',
            onPressed: () => _showCategoryDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Category'),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    ExpenseProvider provider,
    List<CategoryModel> categoriesList,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (categoriesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 56,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'No Categories Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "+ Add Category" to create a custom category',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      itemCount: categoriesList.length,
      itemBuilder: (context, index) {
        final category = categoriesList[index];
        final categoryColor = category.isIncome
            ? AppColors.incomeGreen
            : AppColors.primary;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: categoryColor.withAlpha(25),
              child: Icon(
                category.iconData,
                color: categoryColor,
                size: 20,
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              category.isIncome ? 'Income Category' : 'Expense Category',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit category',
                  onPressed: () => _showCategoryDialog(
                    context,
                    categoryToEdit: category,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.expenseRed,
                  ),
                  tooltip: 'Delete category',
                  onPressed: () => _handleDeleteCategory(
                    context,
                    provider,
                    category,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
