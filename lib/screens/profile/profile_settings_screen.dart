import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../categories/categories_screen.dart';

/// Clean and professional Profile and Settings screen powered by Firebase Auth & SQLite.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  /// Displays Currency Selection Dialog allowing users to change their preferred currency.
  void _showCurrencySelectionDialog(
    BuildContext context,
    ExpenseProvider expenseProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Select Currency',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: AppConstants.supportedCurrencies.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final currency = AppConstants.supportedCurrencies[index];
                final isSelected =
                    expenseProvider.currencyCode == currency.code;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withAlpha(20),
                    child: Text(
                      currency.symbol,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    currency.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('${currency.code} (${currency.symbol})'),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    expenseProvider.setCurrency(currency.symbol, currency.code);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Currency updated to ${currency.name} (${currency.symbol})',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Opens dialog to change user password in Firebase Auth.
  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Change Password',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
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

                    final success = await authProvider.updatePassword(
                      newPasswordController.text.trim(),
                    );

                    if (!context.mounted) return;
                    Navigator.of(ctx).pop();

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.errorMessage ??
                                'Failed to update password',
                          ),
                          backgroundColor: AppColors.expenseRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Triggers password reset email with confirmation dialog.
  void _confirmResetPassword(BuildContext context, AuthProvider authProvider) {
    final email = authProvider.userEmail;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a password reset email to:\n\n$email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await authProvider.sendPasswordReset(email);

              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset email sent to $email'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      authProvider.errorMessage ??
                          'Failed to send password reset email',
                    ),
                    backgroundColor: AppColors.expenseRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  /// Clears only the current user's local transactions from SQLite with a destructive confirmation dialog.
  void _confirmClearUserData(
    BuildContext context,
    AuthProvider authProvider,
    ExpenseProvider expenseProvider,
  ) {
    final userId = authProvider.userId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed),
            SizedBox(width: 8),
            Text('Clear Local Data'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ALL local transactions for user ID "$userId"?\n\nThis action cannot be undone and will permanently remove your stored offline transactions from this device.',
        ),
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
              await DatabaseHelper.instance.deleteTransactionsByUserId(userId);
              await expenseProvider.loadTransactions(userId);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All local transactions cleared successfully.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  /// Signs out with confirmation dialog.
  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
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
              await authProvider.signOut();

              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// Displays About App Info Modal Dialog.
  void _showAppInfoDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0+1',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
      children: const [
        SizedBox(height: 12),
        Text(
          'Expense Tracker is a professional personal finance management app built with Flutter, Material 3, Firebase Authentication, and local SQLite database persistence.',
        ),
        SizedBox(height: 8),
        Text('• Architecture: Clean Provider State Management'),
        Text('• Local DB: SQLite (expense_tracker.db)'),
        Text('• Authentication: Firebase Auth'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<AuthProvider, ExpenseProvider>(
      builder: (context, authProvider, expenseProvider, child) {
        final displayName = authProvider.userDisplayName;
        final email = authProvider.userEmail;
        final userId = authProvider.userId;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Profile & Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // 1. Account Profile Header Card
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusLarge),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withAlpha(20)
                          : Colors.grey.withAlpha(35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 40 : 10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary.withAlpha(40),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          'UID: $userId',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Preferences & Currency Section
                _buildSectionTitle(context, 'Preferences & Currency'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.currency_exchange_rounded),
                        title: const Text('Currency Type'),
                        subtitle: Text(
                          '${expenseProvider.currencyCode} (${expenseProvider.currencySymbol})',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            _showCurrencySelectionDialog(context, expenseProvider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Account Security Section
                _buildSectionTitle(context, 'Account & Security'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset_rounded),
                        title: const Text('Change Password'),
                        subtitle:
                            const Text('Update your Firebase Auth password'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            _showChangePasswordDialog(context, authProvider),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.mark_email_read_outlined),
                        title: const Text('Reset Password'),
                        subtitle:
                            const Text('Send password reset email link'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            _confirmResetPassword(context, authProvider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Category & Data Management Section
                _buildSectionTitle(context, 'Category & Data Management'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: const Text('Manage Categories'),
                        subtitle: const Text('Add, edit or delete income & expense categories'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategoriesScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_sweep_rounded,
                          color: AppColors.expenseRed,
                        ),
                        title: const Text(
                          'Clear Local Transaction Data',
                          style: TextStyle(color: AppColors.expenseRed),
                        ),
                        subtitle: const Text(
                          'Delete only your local SQLite transactions',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.expenseRed,
                        ),
                        onTap: () => _confirmClearUserData(
                          context,
                          authProvider,
                          expenseProvider,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. App Info & Logout Section
                _buildSectionTitle(context, 'App & Session'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('App Information'),
                        subtitle: const Text('Version 1.0.0+1 • System Info'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showAppInfoDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.expenseRed,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            color: AppColors.expenseRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text('Sign out of your session'),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.expenseRed,
                        ),
                        onTap: () => _confirmLogout(context, authProvider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}
