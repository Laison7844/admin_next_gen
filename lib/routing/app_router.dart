import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/admin_config.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/presentation/admin_shell.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/enquiries/presentation/enquiry_list_screen.dart';
import '../features/home_cms/models/home_section_definition.dart';
import '../features/home_cms/presentation/home_cms_screen.dart';
import '../features/home_cms/presentation/standalone_section_screen.dart';
import '../features/media/presentation/media_library_screen.dart';
import '../features/testimonials/presentation/testimonials_screen.dart';
import 'route_paths.dart';

/// Helper to bridge a Dart Stream to a Flutter Listenable for GoRouter.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider for the application GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authService.currentUser != null;
      final isLoginRoute = state.uri.path == RoutePaths.login;

      // 1. Unauthenticated users must be redirected to the login page
      if (!isAuthenticated) {
        return isLoginRoute ? null : RoutePaths.login;
      }

      // 2. Reject unauthorized accounts even if authenticated
      if (!AdminConfig.isAuthorizedAdmin(authService.currentUser)) {
        authService.signOut();
        return RoutePaths.login;
      }

      // 3. Authenticated authorized admins are prevented from returning to login or root
      if (isLoginRoute || state.uri.path == RoutePaths.root) {
        return RoutePaths.dashboard;
      }

      // Allowed to continue to requested destination
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(child: child);
        },
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const HomeCmsScreen(),
          ),
          GoRoute(
            path: RoutePaths.about,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('about_us'),
            ),
          ),
          GoRoute(
            path: RoutePaths.courses,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('courses'),
            ),
          ),
          GoRoute(
            path: RoutePaths.programs,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('programs'),
            ),
          ),
          GoRoute(
            path: RoutePaths.whyNextGen,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('why_nextgen'),
            ),
          ),
          GoRoute(
            path: RoutePaths.learningModes,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('learning_modes'),
            ),
          ),
          GoRoute(
            path: RoutePaths.pledge,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('pledge'),
            ),
          ),
          GoRoute(
            path: RoutePaths.assessments,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('assessments'),
            ),
          ),
          GoRoute(
            path: RoutePaths.bannerCta,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('banner_cta'),
            ),
          ),
          GoRoute(
            path: RoutePaths.gallery,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('gallery'),
            ),
          ),
          GoRoute(
            path: RoutePaths.faqs,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('faqs'),
            ),
          ),
          GoRoute(
            path: RoutePaths.contactFooter,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('contact_footer'),
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            builder: (context, state) => StandaloneSectionScreen(
              section: HomeSectionDefinition.getById('contact_footer'),
            ),
          ),
          GoRoute(
            path: RoutePaths.enquiries,
            builder: (context, state) => const EnquiryListScreen(),
          ),
          GoRoute(
            path: RoutePaths.mediaLibrary,
            builder: (context, state) => const MediaLibraryScreen(),
          ),
          GoRoute(
            path: RoutePaths.testimonials,
            builder: (context, state) => const TestimonialsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.path}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.dashboard),
              child: const Text('Return to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
