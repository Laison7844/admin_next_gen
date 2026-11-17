import 'package:admin_next_gen/core/constants/app_strings.dart';
import 'package:admin_next_gen/core/theme/app_theme.dart';
import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/auth/presentation/login_screen.dart';
import 'package:admin_next_gen/features/auth/providers/auth_provider.dart';
import 'package:admin_next_gen/features/auth/services/auth_service.dart';
import 'package:admin_next_gen/features/dashboard/presentation/models/nav_item.dart';
import 'package:admin_next_gen/features/dashboard/presentation/placeholder_screen.dart';
import 'package:admin_next_gen/routing/route_paths.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService implements AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthException('Invalid email or password.');
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  group('Phase 1 - Theme & Navigation Tests', () {
    test('AppTheme loads correctly with Material 3', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('All 17 required navigation items are configured with unique routes', () {
      expect(NavItem.items.length, 17);

      final routes = NavItem.items.map((e) => e.route).toSet();
      expect(routes.length, 17);

      expect(routes.contains(RoutePaths.dashboard), isTrue);
      expect(routes.contains(RoutePaths.home), isTrue);
      expect(routes.contains(RoutePaths.whyNextGen), isTrue);
      expect(routes.contains(RoutePaths.learningModes), isTrue);
      expect(routes.contains(RoutePaths.pledge), isTrue);
      expect(routes.contains(RoutePaths.assessments), isTrue);
      expect(routes.contains(RoutePaths.bannerCta), isTrue);
      expect(routes.contains(RoutePaths.about), isTrue);
      expect(routes.contains(RoutePaths.courses), isTrue);
      expect(routes.contains(RoutePaths.programs), isTrue);
      expect(routes.contains(RoutePaths.gallery), isTrue);
      expect(routes.contains(RoutePaths.testimonials), isTrue);
      expect(routes.contains(RoutePaths.faqs), isTrue);
      expect(routes.contains(RoutePaths.contactFooter), isTrue);
      expect(routes.contains(RoutePaths.enquiries), isTrue);
      expect(routes.contains(RoutePaths.mediaLibrary), isTrue);
      expect(routes.contains(RoutePaths.settings), isTrue);
    });
  });

  group('Phase 1 - Auth Exception Mapping Tests', () {
    test('AuthException stores message and code', () {
      const exception = AuthException('Invalid credentials', 'invalid-credential');
      expect(exception.message, 'Invalid credentials');
      expect(exception.code, 'invalid-credential');
      expect(exception.toString(), 'Invalid credentials');
    });
  });

  group('Phase 1 - Presentation Widget Tests', () {
    testWidgets('PlaceholderScreen renders title and scheduled phase banner',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaceholderScreen(
              title: 'Courses',
              icon: Icons.menu_book,
              description: 'Manage course catalog and syllabus details',
            ),
          ),
        ),
      );

      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Courses Management'), findsOneWidget);
      expect(
        find.text('Manage course catalog and syllabus details'),
        findsOneWidget,
      );
      expect(
        find.text('Navigation Placeholder • Scheduled for Phase 2'),
        findsOneWidget,
      );
    });

    testWidgets('LoginScreen renders email, password inputs, and sign in button',
        (WidgetTester tester) async {
      final fakeAuth = FakeAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text(AppStrings.institutionName), findsOneWidget);
      expect(find.text(AppStrings.emailLabel), findsOneWidget);
      expect(find.text(AppStrings.passwordLabel), findsOneWidget);
      expect(find.text(AppStrings.signInButton), findsOneWidget);

      await tester.tap(find.text(AppStrings.signInButton));
      await tester.pump();

      expect(find.text('Please enter your admin email.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });
  });
}
