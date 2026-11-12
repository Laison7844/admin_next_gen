import 'package:firebase_auth/firebase_auth.dart';

/// Custom exception class for authentication errors with user-friendly messages.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Service handling Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed in user, if any.
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently logged in.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Signs in the admin user using email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'An unexpected error occurred during sign-in. Please try again.',
      );
    }
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out. Please try again.');
    }
  }

  /// Converts Firebase error codes to user-friendly messages.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This administrator account has been disabled. Contact system support.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Access temporarily restricted for security. Please try again in a few minutes.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

