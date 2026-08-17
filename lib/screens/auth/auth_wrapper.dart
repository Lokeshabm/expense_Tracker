import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';

/// AuthWrapper listens to authentication state and automatically renders either
/// MainNavigationScreen (Dashboard) if logged in, or LoginScreen if logged out.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // While Firebase is initializing the initial session check:
        if (!authProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        // If authenticated, navigate to Dashboard / Main Screen
        if (authProvider.isAuthenticated) {
          return const MainNavigationScreen();
        }

        // Otherwise, render Login Screen
        return const LoginScreen();
      },
    );
  }
}
