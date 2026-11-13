import 'package:admin_next_gen/core/constants/admin_config.dart';
import 'package:admin_next_gen/core/constants/app_strings.dart';
import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/auth/presentation/login_screen.dart';
import 'package:admin_next_gen/features/auth/providers/auth_provider.dart';
import 'package:admin_next_gen/features/auth/services/auth_service.dart';
import 'package:admin_next_gen/features/content/data/content_repository.dart';
import 'package:admin_next_gen/features/content/models/cms_content_item.dart';
import 'package:admin_next_gen/features/content/models/content_type.dart';
import 'package:admin_next_gen/features/content/models/publish_status.dart';
import 'package:admin_next_gen/features/content/providers/content_provider.dart';
import 'package:admin_next_gen/features/dashboard/presentation/placeholder_screen.dart';
import 'package:admin_next_gen/features/enquiries/data/enquiry_repository.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_item.dart';
import 'package:admin_next_gen/features/enquiries/presentation/enquiry_list_screen.dart';
import 'package:admin_next_gen/features/enquiries/providers/enquiry_provider.dart';
import 'package:admin_next_gen/features/home_cms/models/home_section_definition.dart';
import 'package:admin_next_gen/features/home_cms/presentation/home_cms_screen.dart';
import 'package:admin_next_gen/features/home_cms/presentation/standalone_section_screen.dart';
import 'package:admin_next_gen/features/home_cms/presentation/widgets/collection_section_view.dart';
import 'package:admin_next_gen/features/home_cms/presentation/widgets/singleton_section_editor.dart';
import 'package:admin_next_gen/routing/app_router.dart';
import 'package:admin_next_gen/routing/route_paths.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

class MemoryContentRepository implements ContentRepository {
  final Map<String, CmsContentItem> drafts = {};
  final Map<String, Map<String, dynamic>> published = {};

  @override
  Future<List<CmsContentItem>> getDrafts({String? contentType}) async {
    if (contentType == null) return drafts.values.toList();
    return drafts.values.where((d) => d.contentType == contentType).toList();
  }

  @override
  Future<CmsContentItem?> getDraft(String id) async => drafts[id];

  @override
  Future<Map<String, dynamic>?> getPublishedItem(
    String contentType,
    String id,
  ) async {
    return published['${contentType}_$id'];
  }

  @override
  Future<void> saveDraft(CmsContentItem item) async {
    drafts[item.id] = item;
  }

  @override
  Future<void> publish(String draftId, {DateTime? expectedUpdatedAt}) async {
    final draft = drafts[draftId];
    if (draft == null) throw StateError('Draft "$draftId" not found');
    final pubKey = '${draft.publicCollection}_$draftId';
    published[pubKey] = Map<String, dynamic>.from(draft.data);
    drafts[draftId] = draft.copyWith(
      publishStatus: PublishStatus.published,
      hasUnpublishedChanges: false,
      publishedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> unpublish(String draftId) async {
    final draft = drafts[draftId];
    if (draft == null) throw StateError('Draft "$draftId" not found');
    final pubKey = '${draft.publicCollection}_$draftId';
    published.remove(pubKey);
    drafts[draftId] = draft.copyWith(
      publishStatus: PublishStatus.draft,
      hasUnpublishedChanges: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> delete(String draftId) async {
    final draft = drafts[draftId];
    if (draft != null) {
      published.remove('${draft.publicCollection}_$draftId');
    }
    drafts.remove(draftId);
  }
}

class FakeEnquiryRepo implements EnquiryRepository {
  @override
  Future<List<EnquiryItem>> getEnquiries({int limit = 100}) async => [];

  @override
  Future<EnquiryItem?> getEnquiryByPhone(String phone) async => null;

  @override
  Future<void> updateEnquiryStatus(String phone, bool status) async {}

  @override
  Future<void> deleteEnquiry(String phone) async {}
}

void main() {
  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  group('Phase 4.6 — HomeSectionDefinition Helper Tests', () {
    test('getById returns correct section definition for all routes', () {
      final about = HomeSectionDefinition.getById('about_us');
      expect(about.id, 'about_us');
      expect(about.isSingleton, isTrue);
      expect(about.contentType, ContentType.siteSections);

      final courses = HomeSectionDefinition.getById('courses');
      expect(courses.id, 'courses');
      expect(courses.isCollection, isTrue);
      expect(courses.contentType, ContentType.courses);

      final programs = HomeSectionDefinition.getById('programs');
      expect(programs.id, 'programs');
      expect(programs.isCollection, isTrue);
      expect(programs.contentType, ContentType.programs);

      final gallery = HomeSectionDefinition.getById('gallery');
      expect(gallery.id, 'gallery');
      expect(gallery.isCollection, isTrue);
      expect(gallery.contentType, ContentType.gallery);

      final faqs = HomeSectionDefinition.getById('faqs');
      expect(faqs.id, 'faqs');
      expect(faqs.isCollection, isTrue);
      expect(faqs.contentType, ContentType.faqs);

      final settings = HomeSectionDefinition.getById('contact_footer');
      expect(settings.id, 'contact_footer');
      expect(settings.isSingleton, isTrue);
      expect(settings.contentType, ContentType.siteSections);
    });

    test('findById returns null and getById throws for invalid id', () {
      expect(HomeSectionDefinition.findById('non_existent'), isNull);
      expect(
        () => HomeSectionDefinition.getById('non_existent'),
        throwsArgumentError,
      );
    });
  });

  group('Phase 4.6 — StandaloneSectionScreen Widget Tests', () {
    testWidgets('About Us renders SingletonSectionEditor with target info',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MemoryContentRepository();
      final section = HomeSectionDefinition.getById('about_us');

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

      expect(find.text('About Us'), findsOneWidget);
      expect(find.text('Singleton Document'), findsOneWidget);
      expect(
        find.textContaining('site_sections/about_us'),
        findsOneWidget,
      );
      expect(find.byType(SingletonSectionEditor), findsOneWidget);
      expect(find.text('Save Draft'), findsAtLeastNWidgets(1));
    });

    testWidgets('FAQs renders CollectionSectionView with target info and search',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
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
      expect(find.text('Multi-Item Collection'), findsOneWidget);
      expect(
        find.textContaining('faqs/*'),
        findsOneWidget,
      );
      expect(find.byType(CollectionSectionView), findsOneWidget);
      expect(find.text('Add New FAQs Item'), findsOneWidget);
      expect(find.text('Load Default Website Data'), findsOneWidget);
    });

    testWidgets('Courses renders CollectionSectionView', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MemoryContentRepository();
      final section = HomeSectionDefinition.getById('courses');

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

      expect(find.text('Courses'), findsOneWidget);
      expect(find.byType(CollectionSectionView), findsOneWidget);
      expect(find.text('Add New Courses Item'), findsOneWidget);
    });

    testWidgets('Special Programs renders CollectionSectionView',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MemoryContentRepository();
      final section = HomeSectionDefinition.getById('programs');

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

      expect(find.text('Special Programs'), findsOneWidget);
      expect(find.byType(CollectionSectionView), findsOneWidget);
      expect(find.text('Add New Special Programs Item'), findsOneWidget);
    });

    testWidgets('Gallery renders CollectionSectionView', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MemoryContentRepository();
      final section = HomeSectionDefinition.getById('gallery');

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

      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byType(CollectionSectionView), findsOneWidget);
      expect(find.text('Add New Gallery Item'), findsOneWidget);
    });

    testWidgets('Settings renders SingletonSectionEditor for contact_footer',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MemoryContentRepository();
      final section = HomeSectionDefinition.getById('contact_footer');

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

      expect(find.text('Contact & Footer'), findsOneWidget);
      expect(find.byType(SingletonSectionEditor), findsOneWidget);
      expect(
        find.textContaining('site_sections/contact_footer'),
        findsOneWidget,
      );
    });
  });

  group('Phase 4.6 — Router Integration & Auth Guard Tests', () {
    testWidgets('Unauthenticated visitor is redirected to login for any route',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authService = FakeAuthService(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(AppStrings.loginSubtitle), findsOneWidget);
    });

    testWidgets('Authenticated admin can access all 6 standalone routes and home',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final adminUser = MockUser(uid: AdminConfig.authorizedAdminUid);
      final authService = FakeAuthService(adminUser);
      final repo = MemoryContentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
            contentRepositoryProvider.overrideWithValue(repo),
            enquiryRepositoryProvider.overrideWithValue(FakeEnquiryRepo()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final element = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(element);
      final router = container.read(appRouterProvider);

      // 1. FAQs route
      router.go(RoutePaths.faqs);
      await tester.pumpAndSettle();
      expect(find.byType(StandaloneSectionScreen), findsOneWidget);
      expect(find.byType(CollectionSectionView), findsOneWidget);
      expect(find.text('FAQs'), findsWidgets);

      // 2. Courses route
      router.go(RoutePaths.courses);
      await tester.pumpAndSettle();
      expect(find.byType(StandaloneSectionScreen), findsOneWidget);
      expect(find.byType(CollectionSectionView), findsOneWidget);
      expect(find.text('Courses'), findsWidgets);

      // 3. Programs route
      router.go(RoutePaths.programs);
      await tester.pumpAndSettle();
      expect(find.byType(StandaloneSectionScreen), findsOneWidget);
      expect(find.byType(CollectionSectionView), findsOneWidget);
      expect(find.text('Special Programs'), findsWidgets);

      // 4. Gallery route
      router.go(RoutePaths.gallery);
      await tester.pumpAndSettle();
      expect(find.byType(StandaloneSectionScreen), findsOneWidget);
      expect(find.byType(CollectionSectionView), findsOneWidget);
      expect(find.text('Gallery'), findsWidgets);

      // 5. About route
      router.go(RoutePaths.about);
      await tester.pumpAndSettle();
      expect(find.byType(StandaloneSectionScreen), findsOneWidget);
      expect(find.byType(SingletonSectionEditor), findsOneWidget);
      expect(find.text('About Us'), findsWidgets);

      // 6. Settings route
      router.go(RoutePaths.settings);
      await tester.pumpAndSettle();
      expect(find.byType(StandaloneSectionScreen), findsOneWidget);
      expect(find.byType(SingletonSectionEditor), findsOneWidget);
      expect(find.text('Contact & Footer'), findsWidgets);

      // 7. Home CMS route remains intact with all 13 sections
      router.go(RoutePaths.home);
      await tester.pumpAndSettle();
      expect(find.byType(HomeCmsScreen), findsOneWidget);
      expect(find.text('13 Home Page Content Modules'), findsOneWidget);

      // 8. Enquiries route
      router.go(RoutePaths.enquiries);
      await tester.pumpAndSettle();
      expect(find.byType(EnquiryListScreen), findsOneWidget);
      expect(find.text('Admissions Enquiries'), findsWidgets);

      // 9. Placeholders preserved for non-implemented routes
      router.go(RoutePaths.mediaLibrary);
      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderScreen), findsOneWidget);

      router.go(RoutePaths.testimonials);
      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderScreen), findsOneWidget);
    });
  });

  group('Phase 4.6 — Standalone Publishing Lifecycle Tests', () {
    testWidgets('Standalone FAQs view can seed, edit, and publish',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
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

      // Trigger "Load Default Website Data"
      await tester.tap(find.text('Load Default Website Data'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Load Default FAQs?'), findsOneWidget);
      await tester.tap(find.text('Load Defaults'));
      await tester.pumpAndSettle();

      // Check that 6 FAQs were seeded into drafts
      expect(repo.drafts.length, 6);
      expect(find.text('DRAFT ONLY'), findsNWidgets(6));

      // Publish the first FAQ
      final publishButton = find.widgetWithIcon(IconButton, Icons.cloud_upload_outlined);
      expect(publishButton, findsAtLeastNWidgets(1));
      await tester.tap(publishButton.first);
      await tester.pumpAndSettle();

      // Confirm publish dialog
      expect(find.text('Publish Item to Live Website?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Publish Live'));
      await tester.pumpAndSettle();

      // Check published in repo
      expect(repo.published.length, 1);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('DRAFT ONLY'), findsNWidgets(5));
    });
  });
}
