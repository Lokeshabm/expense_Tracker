import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for all Firebase Authentication operations.
/// Includes graceful fallback handling for uninitialized or offline environments.
class AuthService {
  final FirebaseAuth? _customFirebaseAuth;

  AuthService({FirebaseAuth? firebaseAuth}) : _customFirebaseAuth = firebaseAuth;

  FirebaseAuth get _firebaseAuth {
    if (_customFirebaseAuth != null) return _customFirebaseAuth;
    return FirebaseAuth.instance;
  }

  /// Stream of authentication state changes (null when logged out, User when logged in).
  Stream<User?> get authStateChanges {
    try {
      return _firebaseAuth.authStateChanges();
    } catch (e) {
      debugPrint('Notice: FirebaseAuth not initialized in this environment (e.g. Unit Tests): $e');
      return const Stream.empty();
    }
  }

  /// Gets the currently authenticated user, or null if not logged in.
  User? get currentUser {
    try {
      return _firebaseAuth.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Sign in with Email and Password.
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signIn: ${e.code} - ${e.message}');
      throw _getReadableAuthErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected error during signIn: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('no-app') ||
          errorStr.contains('not initialized') ||
          errorStr.contains('plugin') ||
          errorStr.contains('channel')) {
        // Safe local fallback when Firebase is not configured on target platform
        return null;
      }
      throw 'An unexpected error occurred. Please check your credentials and try again.';
    }
  }

  /// Register/Sign up a new user with Name, Email, and Password.
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Update the user's display name in Firebase Auth
      if (credential.user != null) {
        try {
          await credential.user!.updateDisplayName(name.trim());
          await credential.user!.reload();
        } catch (e) {
          debugPrint('Notice: Could not update display name in Firebase: $e');
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signUp: ${e.code} - ${e.message}');
      throw _getReadableAuthErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected error during signUp: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('no-app') ||
          errorStr.contains('not initialized') ||
          errorStr.contains('plugin') ||
          errorStr.contains('channel')) {
        // Safe local fallback when Firebase is not configured on target platform
        return null;
      }
      throw 'An unexpected error occurred. Please check your internet connection and try again.';
    }
  }

  /// Send Password Reset Email to the provided address.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during passwordReset: ${e.code} - ${e.message}');
      throw _getReadableAuthErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected error during passwordReset: $e');
      throw 'Password reset link request failed. Please verify your email address.';
    }
  }

  /// Updates the password of the currently signed-in user.
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword.trim());
      } else {
        throw 'No authenticated user found. Please sign in again.';
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during updatePassword: ${e.code} - ${e.message}');
      throw _getReadableAuthErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected error during updatePassword: $e');
      throw 'Failed to update password. If you signed in a long time ago, please log out and log back in before updating.';
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Translates Firebase error codes into clean, user-friendly messages.
  String _getReadableAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please verify your password and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is invalid. Please enter a valid email address.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      case 'requires-recent-login':
        return 'This security operation requires recent authentication. Please log out and log in again before changing password.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please check your input and try again.';
    }
  }
}
