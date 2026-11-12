import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/admin_config.dart';
import '../services/auth_service.dart';

/// Provider for the AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stream provider for listening to Firebase auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Client-side provider verifying whether the authenticated user meets
/// the single-admin criteria.
final isAuthorizedAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return AdminConfig.isAuthorizedAdmin(user);
});

/// State of the sign-in process.
class AuthSignInState {
  final bool isLoading;
  final String? errorMessage;

  const AuthSignInState({
    this.isLoading = false,
    this.errorMessage,
  });

  AuthSignInState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthSignInState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Controller for login / logout user actions.
class AuthController extends StateNotifier<AuthSignInState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthSignInState());

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!AdminConfig.isAuthorizedAdmin(credential.user)) {
        await _authService.signOut();
        state = const AuthSignInState(
          isLoading: false,
          errorMessage:
              'Access denied: This account is not an authorized administrator.',
        );
        return false;
      }
      state = const AuthSignInState(isLoading: false, errorMessage: null);
      return true;
    } on AuthException catch (e) {
      state = AuthSignInState(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = AuthSignInState(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signOut();
      state = const AuthSignInState(isLoading: false);
    } on AuthException catch (e) {
      state = AuthSignInState(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = const AuthSignInState(
        isLoading: false,
        errorMessage: 'Failed to sign out. Please try again.',
      );
    }
  }
}

/// Provider for the AuthController.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthSignInState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});

