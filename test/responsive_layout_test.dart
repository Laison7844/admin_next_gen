import 'package:admin_next_gen/core/constants/admin_config.dart';
import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/auth/providers/auth_provider.dart';
import 'package:admin_next_gen/features/auth/services/auth_service.dart';
import 'package:admin_next_gen/features/content/data/content_repository.dart';
import 'package:admin_next_gen/features/content/models/cms_content_item.dart';
import 'package:admin_next_gen/features/content/providers/content_provider.dart';
import 'package:admin_next_gen/features/dashboard/presentation/admin_shell.dart';
import 'package:admin_next_gen/features/dashboard/presentation/widgets/admin_header.dart';
import 'package:admin_next_gen/features/dashboard/presentation/widgets/admin_sidebar.dart';
import 'package:admin_next_gen/features/enquiries/data/enquiry_repository.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_item.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_page.dart';
import 'package:admin_next_gen/features/enquiries/presentation/enquiry_list_screen.dart';
import 'package:admin_next_gen/features/enquiries/providers/enquiry_provider.dart';
import 'package:admin_next_gen/features/home_cms/models/home_section_definition.dart';
import 'package:admin_next_gen/features/home_cms/presentation/home_cms_screen.dart';
import 'package:admin_next_gen/features/home_cms/presentation/standalone_section_screen.dart';
import 'package:admin_next_gen/features/media/data/media_repository.dart';
import 'package:admin_next_gen/features/media/models/media_item.dart';
import 'package:admin_next_gen/features/media/presentation/media_library_screen.dart';
import 'package:admin_next_gen/features/testimonials/presentation/testimonials_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;

  MockUser({
    required this.uid,
    this.email = 'admin@nextgen.edu',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final User? _user;
  FakeAuthService([this._user]);

  @override
  Stream<User?> get authStateChanges => Stream.value(_user);

  @override
  User? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryContentRepository implements ContentRepository {
  final Map<String, CmsContentItem> drafts = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CmsContentItem>> getDrafts({String? contentType}) async {
    if (contentType == null) return drafts.values.toList();
    return drafts.values.where((d) => d.contentType == contentType).toList();
  }

  @override
  Future<CmsContentItem?> getDraft(String id) async => drafts[id];

  @override
  Future<void> saveDraft(CmsContentItem item) async {
    drafts[item.id] = item;
  }
}

class FakeEnquiryRepo implements EnquiryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<EnquiryItem>> getEnquiries({
    int limit = 100,
    String? statusFilter,
    String? programFilter,
  }) async => [];

  @override
  Future<EnquiryPage> getEnquiriesPaginated({
    int pageSize = 25,
    dynamic startAfterCursor,
    int pageIndex = 1,
    EnquiryFilter? filter,
  }) async {
    return const EnquiryPage(
      items: [],
      cursor: null,
      hasNextPage: false,
      pageIndex: 1,
      pageSize: 25,
    );
  }
}

class FakeMediaRepo implements MediaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<MediaItem>> getMediaItems({String? folder, bool? forceRefresh}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  final viewports = [
    const Size(320, 600),   // Small mobile
    const Size(375, 812),   // Standard mobile
    const Size(430, 932),   // Large mobile
    const Size(768, 1024),  // Tablet
    const Size(1024, 768),  // Small desktop
    const Size(1440, 900),  // Large desktop
  ];

  group('Phase 4.17 — Responsive Layout & No-Overflow Verification', () {
    for (final size in viewports) {
      testWidgets('AdminShell renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final user = MockUser(uid: AdminConfig.authorizedAdminUid);
        final authService = FakeAuthService(user);

        final testRouter = GoRouter(
          initialLocation: '/dashboard',
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const AdminShell(
                child: Center(child: Text('Dashboard Content')),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWithValue(authService),
            ],
            child: MaterialApp.router(
              routerConfig: testRouter,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(AdminHeader), findsOneWidget);
        if (size.width >= 900) {
          expect(find.byType(AdminSidebar), findsOneWidget);
        } else {
          expect(find.byIcon(Icons.menu), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('HomeCmsScreen renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = MemoryContentRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contentRepositoryProvider.overrideWithValue(repo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: HomeCmsScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Homepage Content'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Standalone FAQs collection view renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = MemoryContentRepository();
        final section = HomeSectionDefinition.getById('faqs');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contentRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              home: StandaloneSectionScreen(section: section),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('FAQs'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('MediaLibraryScreen renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final user = MockUser(uid: AdminConfig.authorizedAdminUid);
        final authService = FakeAuthService(user);
        final mediaRepo = FakeMediaRepo();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWithValue(authService),
              mediaRepositoryProvider.overrideWithValue(mediaRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: MediaLibraryScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Media Library'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('TestimonialsScreen renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = MemoryContentRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contentRepositoryProvider.overrideWithValue(repo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: TestimonialsScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Testimonials'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('EnquiryListScreen renders cleanly at ${size.width.toInt()}x${size.height.toInt()} without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final enquiryRepo = FakeEnquiryRepo();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              enquiryRepositoryProvider.overrideWithValue(enquiryRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: EnquiryListScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Admissions Enquiries'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
