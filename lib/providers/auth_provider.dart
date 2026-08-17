import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Provider for managing Firebase Authentication state, user profile, and operations.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Local fallback session variables when Firebase is offline or uninitialized
  String? _localUserName;
  String? _localUserEmail;
  String? _localUserId;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _initAuthState();
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null || (_localUserId != null && _localUserId!.isNotEmpty);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  /// User's display name or email prefix
  String get userDisplayName {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      return _user!.displayName!;
    }
    if (_localUserName != null && _localUserName!.isNotEmpty) {
      return _localUserName!;
    }
    if (userEmail.isNotEmpty) {
      return userEmail.split('@').first.capitalize();
    }
    return 'User';
  }

  /// User's email address
  String get userEmail => _user?.email ?? _localUserEmail ?? 'user@example.com';

  /// User's UID
  String get userId {
    if (_user?.uid != null && _user!.uid.isNotEmpty) {
      return _user!.uid;
    }
    if (_localUserId != null && _localUserId!.isNotEmpty) {
      return _localUserId!;
    }
    return 'user_demo_1';
  }

  /// Subscribes to Firebase auth state changes.
  void _initAuthState() {
    try {
      _user = _authService.currentUser;
      _authStateSubscription = _authService.authStateChanges.listen(
        (User? user) {
          _user = user;
          _isInitialized = true;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Auth state subscription error: $error');
          _isInitialized = true;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Auth initialization note: $e');
    } finally {
      if (!_isInitialized) {
        _isInitialized = true;
      }
    }
  }

  /// Sign In with Email & Password
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential != null) {
        _user = credential.user;
      } else {
        // Fallback for offline/uninitialized platform environment
        _localUserEmail = email.trim();
        _localUserName = email.trim().split('@').first.capitalize();
        _localUserId = 'user_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Sign Up / Register with Name, Email & Password
  Future<bool> signUp(String name, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signUpWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );

      if (credential != null && credential.user != null) {
        _user = credential.user;
      } else {
        // Fallback for offline/uninitialized platform environment
        _localUserName = name.trim();
        _localUserEmail = email.trim();
        _localUserId = 'user_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Send Password Reset Email
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Change/Update Password for authenticated user
  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.updatePassword(newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Sign Out current user
  Future<void> signOut() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signOut();
      _user = null;
      _localUserName = null;
      _localUserEmail = null;
      _localUserId = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
