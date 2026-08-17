import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import 'dashboard/home_screen.dart';
import 'profile/profile_settings_screen.dart';
import 'reports/monthly_reports_screen.dart';
import 'transactions/add_transaction_screen.dart';
import 'transactions/transaction_history_screen.dart';

/// Main navigation shell containing the Material 3 Navigation Bar, smooth tab transitions, and FAB.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Synchronize authenticated Firebase User ID with ExpenseProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        expenseProvider.setCurrentUserId(authProvider.userId);
      }
    });
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      HomeScreen(
        onNavigateToHistory: () => _onTabSelected(1),
      ),
      const TransactionHistoryScreen(),
      const MonthlyReportsScreen(),
      const ProfileSettingsScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppConstants.animationDurationShort,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 15),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          height: 68,
          indicatorColor: AppColors.primary.withAlpha(isDark ? 70 : 35),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon:
                  Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'main_fab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Record',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
