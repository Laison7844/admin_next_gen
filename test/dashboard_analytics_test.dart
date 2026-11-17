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
import 'package:admin_next_gen/features/dashboard/models/dashboard_analytics.dart';
import 'package:admin_next_gen/features/dashboard/presentation/dashboard_screen.dart';
import 'package:admin_next_gen/features/enquiries/data/enquiry_repository.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_item.dart';
import 'package:admin_next_gen/features/enquiries/models/enquiry_page.dart';
import 'package:admin_next_gen/features/enquiries/providers/enquiry_provider.dart';
import 'package:admin_next_gen/features/media/data/media_repository.dart';
import 'package:admin_next_gen/features/media/models/media_item.dart';
import 'package:admin_next_gen/features/media/services/media_file_picker.dart';
import 'package:admin_next_gen/routing/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================================
// Test Mocks and Fakes
// ============================================================================

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
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class FakeContentRepo implements ContentRepository {
  List<CmsContentItem> items = [];
  Map<String, Set<String>> publishedDocIdsMap = {};
  bool shouldThrow = false;

  FakeContentRepo({
    List<CmsContentItem>? initialItems,
    Map<String, Set<String>>? initialPublishedDocIds,
  })  : items = initialItems ?? [],
        publishedDocIdsMap = initialPublishedDocIds ?? {};

  @override
  Future<Set<String>> getPublishedDocIds(String contentType) async {
    if (shouldThrow) throw StateError('Simulated Content Error');
    return publishedDocIdsMap[contentType] ?? const {};
  }

  @override
  Future<List<CmsContentItem>> getDrafts({String? contentType}) async {
    if (shouldThrow) throw StateError('Simulated Content Error');
    if (contentType == null || contentType.isEmpty) return items;
    return items.where((i) => i.contentType == contentType).toList();
  }

  @override
  Future<CmsContentItem?> getDraft(String id) async =>
      items.where((i) => i.id == id).firstOrNull;

  @override
  Future<Map<String, dynamic>?> getPublishedItem(
          String contentType, String id) async =>
      null;

  @override
  Future<void> saveDraft(CmsContentItem item) async {
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }
  }

  @override
  Future<void> publish(String draftId, {DateTime? expectedUpdatedAt}) async {}

  @override
  Future<void> unpublish(String draftId) async {}

  @override
  Future<void> delete(String draftId) async {
    items.removeWhere((i) => i.id == draftId);
  }
}

class FakeEnquiryRepo implements EnquiryRepository {
  List<EnquiryItem> items = [];
  bool shouldThrow = false;

  FakeEnquiryRepo({List<EnquiryItem>? initialItems})
      : items = initialItems ?? [];

  @override
  Future<List<EnquiryItem>> getEnquiries({int limit = 100}) async {
    if (shouldThrow) throw StateError('Simulated Enquiry Error');
    return items.take(limit).toList();
  }

  @override
  Future<EnquiryPage> getEnquiriesPaginated({
    int pageSize = 25,
    dynamic startAfterCursor,
    int pageIndex = 1,
    EnquiryFilter? filter,
  }) async {
    if (shouldThrow) throw StateError('Simulated Enquiry Error');
    var list = items;
    if (filter != null && !filter.isDefault) {
      list = list.where((e) => filter.matches(e)).toList();
    }
    final start = (pageIndex - 1) * pageSize;
    if (start >= list.length) {
      return EnquiryPage(
        items: const [],
        cursor: null,
        hasNextPage: false,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );
    }
    final end = (start + pageSize).clamp(0, list.length);
    final pageItems = list.sublist(start, end);
    return EnquiryPage(
      items: pageItems,
      cursor: pageItems.isNotEmpty ? pageItems.last.phone : null,
      hasNextPage: end < list.length,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  @override
  Future<EnquiryItem?> getEnquiryByPhone(String phone) async =>
      items.where((e) => e.phone == phone).firstOrNull;

  @override
  Future<void> updateEnquiryStatus(String phone, bool status) async {}

  @override
  Future<void> updateWorkflow({
    required String phone,
    String? workflowStatus,
    String? adminNotes,
  }) async {}

  @override
  Future<void> deleteEnquiry(String phone) async {
    items.removeWhere((e) => e.phone == phone);
  }
}

class FakeMediaRepo implements MediaRepository {
  List<MediaItem> items = [];
  bool shouldThrow = false;

  FakeMediaRepo({List<MediaItem>? initialItems}) : items = initialItems ?? [];

  @override
  Future<List<MediaItem>> getMediaItems({
    String? folder,
    bool forceRefresh = false,
  }) async {
    if (shouldThrow) throw StateError('Simulated Media Error');
    if (folder == null || folder.isEmpty) return items;
    return items.where((m) => m.folder == folder).toList();
  }

  @override
  Future<MediaItem> uploadMedia({
    required SelectedMediaFile file,
    required String folder,
    required String adminUid,
    void Function(double progress)? onProgress,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteMedia(MediaItem item) async {
    items.removeWhere((m) => m.id == item.id);
  }

  @override
  Future<MediaItem?> getMediaByPath(String fullPath) async => null;
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  group('Phase 4.11 — Domain Analytics Calculations', () {
    test('EnquiryAnalytics computes metrics, percentages, and 7-day cutoff accurately', () {
      final now = DateTime(2026, 11, 16, 12, 0);

      final enquiries = [
        EnquiryItem(
          id: '1',
          name: 'Student 1',
          phone: '9876543210',
          program: 'Class 10',
          message: 'Interested in math',
          status: true, // Active
          workflowStatus: EnquiryWorkflowStatus.newStatus,
          createdAt: now.subtract(const Duration(days: 2)), // Within 7 days
        ),
        EnquiryItem(
          id: '2',
          name: 'Student 2',
          phone: '9876543211',
          program: 'JEE Main',
          message: 'Wants physics coaching',
          status: true, // Active
          workflowStatus: EnquiryWorkflowStatus.contacted,
          createdAt: now.subtract(const Duration(days: 4)), // Within 7 days
        ),
        EnquiryItem(
          id: '3',
          name: 'Student 3',
          phone: '9876543212',
          program: 'Foundation',
          message: 'Scholarship enquiry',
          status: true, // Active
          workflowStatus: EnquiryWorkflowStatus.enrolled,
          createdAt: now.subtract(const Duration(days: 10)), // Older than 7 days
        ),
        EnquiryItem(
          id: '4',
          name: 'Student 4',
          phone: '9876543213',
          program: 'NEET',
          message: 'Closed lead',
          status: false, // Archived
          workflowStatus: EnquiryWorkflowStatus.closed,
          createdAt: now.subtract(const Duration(days: 15)), // Older than 7 days
        ),
      ];

      final analytics = EnquiryAnalytics.fromEnquiries(enquiries, referenceTime: now);

      expect(analytics.totalLoaded, 4);
      expect(analytics.activeCount, 3);
      expect(analytics.archivedCount, 1);
      expect(analytics.newCount, 1);
      expect(analytics.contactedCount, 1);
      expect(analytics.enrolledCount, 1);
      expect(analytics.closedCount, 1);
      expect(analytics.last7DaysCount, 2);
      expect(analytics.percentage(1), 25.0);

      // Verify recent enquiries sorting (newest first)
      expect(analytics.recentEnquiries.first.id, '1');
      expect(analytics.recentEnquiries[1].id, '2');
      expect(analytics.recentEnquiries[2].id, '3');
      expect(analytics.recentEnquiries[3].id, '4');
    });

    test('EnquiryAnalytics handles empty enquiry list gracefully', () {
      final empty = EnquiryAnalytics.fromEnquiries(const []);
      expect(empty.totalLoaded, 0);
      expect(empty.activeCount, 0);
      expect(empty.archivedCount, 0);
      expect(empty.newCount, 0);
      expect(empty.contactedCount, 0);
      expect(empty.enrolledCount, 0);
      expect(empty.closedCount, 0);
      expect(empty.last7DaysCount, 0);
      expect(empty.recentEnquiries, isEmpty);
      expect(empty.percentage(5), 0.0);
    });

    test('ContentAnalytics computes published vs draft counts across content types', () {
      final now = DateTime(2026, 11, 16, 10, 0);

      final drafts = [
        CmsContentItem(
          id: 'course_1',
          contentType: ContentType.courses.key,
          title: 'Class 10 CBSE Math',
          data: {},
          publishStatus: PublishStatus.published,
          createdAt: now,
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
        CmsContentItem(
          id: 'course_2',
          contentType: ContentType.courses.key,
          title: 'Class 9 Science Draft',
          data: {},
          publishStatus: PublishStatus.draft,
          createdAt: now,
          updatedAt: now.subtract(const Duration(hours: 3)),
        ),
        CmsContentItem(
          id: 'prog_1',
          contentType: ContentType.programs.key,
          title: 'Special Care 1-to-1',
          data: {},
          publishStatus: PublishStatus.published,
          createdAt: now,
          updatedAt: now.subtract(const Duration(minutes: 30)),
        ),
        CmsContentItem(
          id: 'test_1',
          contentType: ContentType.testimonials.key,
          title: 'Aarav Sharma Review',
          data: {},
          publishStatus: PublishStatus.published,
          createdAt: now,
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
        CmsContentItem(
          id: 'test_2',
          contentType: ContentType.testimonials.key,
          title: 'Draft Review',
          data: {},
          publishStatus: PublishStatus.draft,
          createdAt: now,
          updatedAt: now.subtract(const Duration(hours: 5)),
        ),
        CmsContentItem(
          id: 'sec_hero',
          contentType: ContentType.siteSections.key,
          title: 'Hero Section',
          data: {},
          publishStatus: PublishStatus.published,
          createdAt: now,
          updatedAt: now.subtract(const Duration(minutes: 5)),
        ),
      ];

      final analytics = ContentAnalytics.fromDrafts(drafts);

      expect(analytics.publishedCourses, 1);
      expect(analytics.draftCourses, 1);
      expect(analytics.publishedPrograms, 1);
      expect(analytics.draftPrograms, 0);
      expect(analytics.publishedTestimonials, 1);
      expect(analytics.draftTestimonials, 1);
      expect(analytics.publishedSections, 1);
      expect(analytics.draftSections, 0);
      expect(analytics.totalPublished, 4);
      expect(analytics.totalDrafts, 2);

      // Verify recent updates sorting (newest updatedAt first)
      expect(analytics.recentUpdates.length, 6);
      expect(analytics.recentUpdates.first.id, 'sec_hero'); // 5 min ago
      expect(analytics.recentUpdates[1].id, 'prog_1'); // 30 min ago
      expect(analytics.recentUpdates[2].id, 'course_1'); // 1 hr ago
    });

    test('ContentAnalytics handles empty drafts list safely', () {
      final empty = ContentAnalytics.fromDrafts(const []);
      expect(empty.totalPublished, 0);
      expect(empty.totalDrafts, 0);
      expect(empty.recentUpdates, isEmpty);
    });

    test('MediaAnalytics aggregates total images and folders accurately', () {
      final media = [
        MediaItem(
          id: '1',
          name: 'hero.jpg',
          originalName: 'hero.jpg',
          fullPath: 'media/homepage/hero.jpg',
          downloadUrl: 'https://example.com/1',
          contentType: 'image/jpeg',
          sizeBytes: 1024,
          folder: 'homepage',
        ),
        MediaItem(
          id: '2',
          name: 'lab.jpg',
          originalName: 'lab.jpg',
          fullPath: 'media/gallery/lab.jpg',
          downloadUrl: 'https://example.com/2',
          contentType: 'image/jpeg',
          sizeBytes: 2048,
          folder: 'gallery',
        ),
        MediaItem(
          id: '3',
          name: 'campus.png',
          originalName: 'campus.png',
          fullPath: 'media/gallery/campus.png',
          downloadUrl: 'https://example.com/3',
          contentType: 'image/png',
          sizeBytes: 4096,
          folder: 'gallery',
        ),
      ];

      final analytics = MediaAnalytics.fromMedia(media);

      expect(analytics.totalImages, 3);
      expect(analytics.folderCounts['gallery'], 2);
      expect(analytics.folderCounts['homepage'], 1);
      expect(analytics.folderCounts['courses'], isNull);
    });
  });

  group('Phase 4.11.1 — Publication Metrics Accuracy Audit Tests', () {
    test('Scenario 1: Draft never published is counted as draft and not live', () {
      final now = DateTime.now();
      final drafts = [
        CmsContentItem(
          id: 'course_draft_only',
          contentType: ContentType.courses.key,
          title: 'Unpublished Course',
          data: {},
          publishStatus: PublishStatus.draft,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final publishedDocs = <String, Set<String>>{
        'courses': <String>{}, // Nothing in public collection
      };

      final analytics = ContentAnalytics.fromDrafts(
        drafts,
        publishedDocIds: publishedDocs,
      );

      expect(analytics.publishedCourses, 0);
      expect(analytics.draftCourses, 1);
    });

    test('Scenario 2: Published item subsequently unpublished is removed from live count', () {
      final now = DateTime.now();
      final drafts = [
        CmsContentItem(
          id: 'course_unpub',
          contentType: ContentType.courses.key,
          title: 'Unpublished Item',
          data: {},
          publishStatus: PublishStatus.draft, // Status changed to draft
          hasUnpublishedChanges: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Public collection document was deleted by unpublish()
      final publishedDocs = <String, Set<String>>{
        'courses': <String>{},
      };

      final analytics = ContentAnalytics.fromDrafts(
        drafts,
        publishedDocIds: publishedDocs,
      );

      expect(analytics.publishedCourses, 0);
      expect(analytics.draftCourses, 1);
    });

    test('Scenario 3: Published draft whose public document was deleted is NOT counted as live', () {
      final now = DateTime.now();
      // Draft still thinks it is published
      final drafts = [
        CmsContentItem(
          id: 'course_deleted_publicly',
          contentType: ContentType.courses.key,
          title: 'Orphaned Draft',
          data: {},
          publishStatus: PublishStatus.published,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // BUT public Firestore collection does NOT contain it
      final publishedDocs = <String, Set<String>>{
        'courses': <String>{},
      };

      final analytics = ContentAnalytics.fromDrafts(
        drafts,
        publishedDocIds: publishedDocs,
      );

      expect(analytics.publishedCourses, 0,
          reason: 'Must NOT count as live if missing from public collection.');
      expect(analytics.draftCourses, 1);
    });

    test('Scenario 4: Draft modified without republishing preserves live count', () {
      final now = DateTime.now();
      final drafts = [
        CmsContentItem(
          id: 'course_modified',
          contentType: ContentType.courses.key,
          title: 'Modified Course Draft',
          data: {},
          publishStatus: PublishStatus.published,
          hasUnpublishedChanges: true, // Modified in draft
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Previous version is still live in public collection
      final publishedDocs = <String, Set<String>>{
        'courses': {'course_modified'},
      };

      final analytics = ContentAnalytics.fromDrafts(
        drafts,
        publishedDocIds: publishedDocs,
      );

      expect(analytics.publishedCourses, 1,
          reason: 'Still live on public website until unpublished or deleted.');
      expect(analytics.draftCourses, 0);
    });

    test('Scenario 5: Published item with public document is counted as live', () {
      final now = DateTime.now();
      final drafts = [
        CmsContentItem(
          id: 'prog_live',
          contentType: ContentType.programs.key,
          title: 'Live Program',
          data: {},
          publishStatus: PublishStatus.published,
          hasUnpublishedChanges: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final publishedDocs = <String, Set<String>>{
        'programs': {'prog_live'},
      };

      final analytics = ContentAnalytics.fromDrafts(
        drafts,
        publishedDocIds: publishedDocs,
      );

      expect(analytics.publishedPrograms, 1);
      expect(analytics.draftPrograms, 0);
    });

    test('Scenario 6: Public document existing without draft metadata is counted as live', () {
      // E.g. direct Firestore document seeded before CMS was initialized
      final drafts = <CmsContentItem>[]; // No draft in cms_drafts

      final publishedDocs = <String, Set<String>>{
        'courses': {'class_10_cbse', 'class_9_foundation'},
        'gallery': {'photo_1', 'photo_2', 'photo_3'},
      };

      final analytics = ContentAnalytics.fromDrafts(
        drafts,
        publishedDocIds: publishedDocs,
      );

      expect(analytics.publishedCourses, 2,
          reason: 'Must count actual public documents even if draft is absent.');
      expect(analytics.publishedGallery, 3);
    });

    test('Singleton Sections: Counts ONLY actual documents in site_sections; does NOT report all 9 as live', () {
      // Suppose only 2 singleton sections are seeded/published in site_sections
      final publishedDocs = <String, Set<String>>{
        'site_sections': {'home_hero', 'about_us'},
      };

      final analytics = ContentAnalytics.fromDrafts(
        const [],
        publishedDocIds: publishedDocs,
      );

      expect(analytics.publishedSections, 2,
          reason: 'Only sections actually in site_sections must be counted.');
    });

    test('Singleton Sections: Handles 0 published sections and missing documents correctly', () {
      final publishedDocs = <String, Set<String>>{
        'site_sections': <String>{}, // None seeded yet
      };

      final analytics = ContentAnalytics.fromDrafts(
        const [],
        publishedDocIds: publishedDocs,
      );

      expect(analytics.publishedSections, 0,
          reason: 'Unseeded or missing sections must yield 0, not default 9.');
    });
  });

  group('Phase 4.11 — Dashboard Screen & Widgets UI Tests', () {
    late FakeAuthService fakeAuthService;
    late FakeContentRepo fakeContentRepo;
    late FakeEnquiryRepo fakeEnquiryRepo;
    late FakeMediaRepo fakeMediaRepo;

    setUp(() {
      fakeAuthService = FakeAuthService(
        MockUser(uid: AdminConfig.authorizedAdminUid, email: 'admin@nextgen.edu'),
      );
      fakeContentRepo = FakeContentRepo();
      fakeEnquiryRepo = FakeEnquiryRepo();
      fakeMediaRepo = FakeMediaRepo();
    });

    Widget createTestApp({
      EnquiryRepository? enquiryRepo,
      ContentRepository? contentRepo,
      MediaRepository? mediaRepo,
    }) {
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(fakeAuthService),
          enquiryRepositoryProvider.overrideWithValue(enquiryRepo ?? fakeEnquiryRepo),
          contentRepositoryProvider.overrideWithValue(contentRepo ?? fakeContentRepo),
          mediaRepositoryProvider.overrideWithValue(mediaRepo ?? fakeMediaRepo),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('Renders welcome banner, admin email, and all dashboard sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Welcome Banner
      expect(find.text('Welcome back, admin@nextgen.edu'), findsOneWidget);
      expect(find.text('Administrator Portal • Authorized Session'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      // Section Headers
      expect(find.text('Admissions Enquiries Overview'), findsOneWidget);
      expect(find.text('Enquiry Workflow Progress'), findsOneWidget);
      expect(find.text('Website Content Overview'), findsOneWidget);
      expect(find.text('Media Library Overview'), findsOneWidget);
      expect(find.text('Recent Admissions Enquiries'), findsOneWidget);
      expect(find.text('Recently Updated CMS Content'), findsOneWidget);
      expect(find.text('Quick Navigation Shortcuts'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Displays dynamic enquiry metrics and workflow breakdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));

      final now = DateTime.now();
      fakeEnquiryRepo.items = [
        EnquiryItem(
          id: '1',
          name: 'Priya Sharma',
          phone: '9876543210',
          program: 'Class 10 Excellence',
          message: 'Interested in morning batch',
          status: true,
          workflowStatus: EnquiryWorkflowStatus.newStatus,
          createdAt: now,
        ),
        EnquiryItem(
          id: '2',
          name: 'Rahul Verma',
          phone: '9876543211',
          program: 'JEE Advanced',
          message: 'Test series details',
          status: false,
          workflowStatus: EnquiryWorkflowStatus.contacted,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Enquiry Metric Tiles
      expect(find.text('2'), findsWidgets); // Total Loaded
      expect(find.text('1'), findsWidgets); // Active & Archived counts
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('CONTACTED'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Displays content analytics and publication badges', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));

      final now = DateTime.now();
      fakeContentRepo.publishedDocIdsMap = {
        'courses': {'c1'},
      };
      fakeContentRepo.items = [
        CmsContentItem(
          id: 'c1',
          contentType: ContentType.courses.key,
          title: 'Class 10 CBSE Math',
          data: {},
          publishStatus: PublishStatus.published,
          createdAt: now,
          updatedAt: now,
        ),
        CmsContentItem(
          id: 'p1',
          contentType: ContentType.programs.key,
          title: 'Special Care Track',
          data: {},
          publishStatus: PublishStatus.draft,
          createdAt: now,
          updatedAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Class 10 CBSE Math'), findsOneWidget);
      expect(find.text('Special Care Track'), findsOneWidget);
      expect(find.text('1 Live'), findsWidgets);
      expect(find.text('1 Drafts'), findsWidgets);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Displays media library stats and folder categories', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));

      fakeMediaRepo.items = [
        MediaItem(
          id: 'm1',
          name: 'campus.jpg',
          originalName: 'campus.jpg',
          fullPath: 'media/gallery/campus.jpg',
          downloadUrl: 'https://example.com/m1',
          contentType: 'image/jpeg',
          sizeBytes: 1024,
          folder: 'gallery',
        ),
      ];

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Total Uploaded Assets'), findsOneWidget);
      expect(find.text('Open Library'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Handles empty states cleanly across all widgets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));

      // With empty repos
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('No Admissions Enquiries Received Yet'), findsOneWidget);
      expect(find.text('No Content Updates Recorded'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Manual refresh triggers reload without throwing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final refreshBtn = find.text('Refresh');
      expect(refreshBtn, findsOneWidget);

      await tester.tap(refreshBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Refresh'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Handles error states gracefully when repository throws', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));

      fakeEnquiryRepo.shouldThrow = true;
      fakeContentRepo.shouldThrow = true;
      fakeMediaRepo.shouldThrow = true;

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to load admissions enquiries'), findsOneWidget);
      expect(find.textContaining('Unable to load website content metrics'), findsOneWidget);
      expect(find.textContaining('Failed to read media library'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Phase 4.11 — Security & Navigation Access Tests', () {
    testWidgets('Unauthorized non-admin visitor is denied access to dashboard', (tester) async {
      final unauthAuthService = FakeAuthService(
        MockUser(uid: 'unauthorized_attacker_uid', email: 'attacker@evil.com'),
      );

      final fakeContent = FakeContentRepo();
      final fakeEnquiries = FakeEnquiryRepo();
      final fakeMedia = FakeMediaRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(unauthAuthService),
            contentRepositoryProvider.overrideWithValue(fakeContent),
            enquiryRepositoryProvider.overrideWithValue(fakeEnquiries),
            mediaRepositoryProvider.overrideWithValue(fakeMedia),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must be redirected to login screen, NOT dashboard
      expect(find.byType(DashboardScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(AppStrings.loginSubtitle), findsOneWidget);
    });

    testWidgets('Verified admin UID can access dashboard route directly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));

      final authAdmin = FakeAuthService(
        MockUser(uid: AdminConfig.authorizedAdminUid, email: 'admin@nextgen.edu'),
      );

      final fakeContent = FakeContentRepo();
      final fakeEnquiries = FakeEnquiryRepo();
      final fakeMedia = FakeMediaRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authAdmin),
            contentRepositoryProvider.overrideWithValue(fakeContent),
            enquiryRepositoryProvider.overrideWithValue(fakeEnquiries),
            mediaRepositoryProvider.overrideWithValue(fakeMedia),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Welcome back, admin@nextgen.edu'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
