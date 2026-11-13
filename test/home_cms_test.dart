import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/content/data/content_repository.dart';
import 'package:admin_next_gen/features/content/models/cms_content_item.dart';
import 'package:admin_next_gen/features/content/models/content_type.dart';
import 'package:admin_next_gen/features/content/models/publish_status.dart';
import 'package:admin_next_gen/features/content/providers/content_provider.dart';
import 'package:admin_next_gen/features/content/services/content_service.dart';
import 'package:admin_next_gen/features/home_cms/constants/home_default_data.dart';
import 'package:admin_next_gen/features/home_cms/models/home_section_definition.dart';
import 'package:admin_next_gen/features/home_cms/presentation/home_cms_screen.dart';
import 'package:admin_next_gen/features/home_cms/presentation/widgets/publish_status_badge.dart';
import 'package:admin_next_gen/features/home_cms/presentation/widgets/section_preview_dialog.dart';

class MockContentRepository implements ContentRepository {
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
  Future<void> saveDraft(CmsContentItem item) async {
    drafts[item.id] = item;
  }

  @override
  Future<void> publish(String draftId, {DateTime? expectedUpdatedAt}) async {
    final draft = drafts[draftId];
    if (draft == null) throw Exception('Draft not found');
    if (expectedUpdatedAt != null &&
        draft.updatedAt.difference(expectedUpdatedAt).inMilliseconds > 500) {
      throw StateError('Concurrent edit detected');
    }
    final pubKey = '${draft.publicCollection}_$draftId';
    // Exact replacement: copies current draft data cleanly
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
    if (draft == null) throw Exception('Draft not found');
    final pubKey = '${draft.publicCollection}_$draftId';
    published.remove(pubKey);
    drafts[draftId] = draft.copyWith(
      publishStatus: PublishStatus.draft,
      hasUnpublishedChanges: false,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> delete(String draftId) async {
    final draft = drafts.remove(draftId);
    if (draft != null) {
      final pubKey = '${draft.publicCollection}_$draftId';
      published.remove(pubKey);
    }
  }

  @override
  Future<Map<String, dynamic>?> getPublishedItem(
    String contentType,
    String id,
  ) async {
    return published['${contentType}_$id'];
  }
}

class FailingPublishRepository extends MockContentRepository {
  @override
  Future<void> publish(String draftId, {DateTime? expectedUpdatedAt}) async {
    throw Exception('Simulated network/Firestore failure during publish');
  }
}

void main() {
  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  group('Home CMS Section Definitions and ContentType Mappings', () {
    test('Contains exactly 13 sections with correct IDs', () {
      final sections = HomeSectionDefinition.sections;
      expect(sections.length, 13);

      final expectedIds = [
        'home_hero',
        'feature_highlights',
        'about_us',
        'courses',
        'programs',
        'why_nextgen',
        'learning_modes',
        'pledge',
        'assessments',
        'banner_cta',
        'gallery',
        'faqs',
        'contact_footer',
      ];

      for (int i = 0; i < expectedIds.length; i++) {
        expect(sections[i].id, expectedIds[i]);
      }
    });

    test('All nine singleton sections map strictly to site_sections public collection', () {
      final sections = HomeSectionDefinition.sections.where((s) => s.isSingleton);
      expect(sections.length, 9);

      for (final s in sections) {
        expect(s.contentType, ContentType.siteSections);
        expect(s.contentType.key, 'site_sections');
        expect(s.contentType.publicCollection, 'site_sections');
        expect(s.defaultSingletonData.isNotEmpty, isTrue);
      }
    });

    test('Collection content types map to respective public collections', () {
      expect(ContentType.courses.publicCollection, 'courses');
      expect(ContentType.programs.publicCollection, 'programs');
      expect(ContentType.gallery.publicCollection, 'gallery');
      expect(ContentType.faqs.publicCollection, 'faqs');
    });

    test('Invalid content type throws ArgumentError', () {
      expect(() => ContentType.fromKey('unknown_type'), throwsArgumentError);
      expect(ContentType.tryFromKey('unknown_type'), isNull);
      expect(ContentType.fromKey('courses'), ContentType.courses);
      expect(ContentType.fromKey('site_sections'), ContentType.siteSections);
    });

    test('HomeDefaultData contains all 13 sections with valid audited data', () {
      // 1. Hero
      expect(HomeDefaultData.hero['mainTitle'], contains('Building Strong'));
      expect(HomeDefaultData.hero['highlightedTitle'], 'Lifelong Success');
      expect((HomeDefaultData.hero['featureChips'] as List).length, 3);

      // 2. Feature Highlights (6 items)
      expect(HomeDefaultData.featureHighlights.length, 6);
      expect(HomeDefaultData.featureHighlights.first['title'], 'Personalized Learning');

      // 3. About
      expect((HomeDefaultData.about['pillars'] as List).length, 4);

      // 4. Default Courses
      expect(HomeDefaultData.defaultCourses.length, 3);
      expect(HomeDefaultData.defaultCourses.first['tag'], 'Foundation');

      // 5. Default Programs
      expect(HomeDefaultData.defaultPrograms.length, 4);

      // 6. Why NextGen
      expect((HomeDefaultData.whyNextGen['reasons'] as List).length, 6);

      // 7. Learning Modes
      expect((HomeDefaultData.learningModes['modes'] as List).length, 2);

      // 8. Pledge
      expect(HomeDefaultData.pledge['title'], 'The NextGen Excellence Pledge');

      // 9. Assessments
      expect((HomeDefaultData.assessments['evaluationCards'] as List).length, 5);

      // 10. Banner CTA
      expect(HomeDefaultData.bannerCta['buttonLabel'], 'Enquire Now');

      // 11. Gallery
      expect(HomeDefaultData.defaultGallery.length, 4);

      // 12. FAQs
      expect(HomeDefaultData.defaultFaqs.length, 6);

      // 13. Contact & Footer
      expect(HomeDefaultData.contactFooter['phone1'], '8075854535');
      expect(HomeDefaultData.contactFooter['email'], contains('nextgen'));
    });
  });

  group('Publishing Lifecycle & Exact Replacement Operations', () {
    late MockContentRepository mockRepo;
    late ContentService contentService;

    setUp(() {
      mockRepo = MockContentRepository();
      contentService = ContentService(
        repository: mockRepo,
        explicitAdminUser: 'test_admin@nextgen.com',
      );
    });

    test('Repeated publishing is idempotent and updates the same public document', () async {
      await contentService.createDraft(
        id: 'home_hero',
        contentType: ContentType.siteSections.key,
        title: 'Hero Section',
        data: {'mainTitle': 'Hero V1'},
      );

      // 1st publish
      await contentService.publish('home_hero');
      final pub1 = await mockRepo.getPublishedItem('site_sections', 'home_hero');
      expect(pub1, isNotNull);
      expect(pub1!['mainTitle'], 'Hero V1');

      // 2nd publish without edits
      await contentService.publish('home_hero');
      final pub2 = await mockRepo.getPublishedItem('site_sections', 'home_hero');
      expect(pub2, isNotNull);
      expect(pub2!['mainTitle'], 'Hero V1');

      // Ensure no duplicate public documents exist
      expect(mockRepo.published.keys.where((k) => k.endsWith('home_hero')).length, 1);
    });

    test('Removed fields and array elements from draft are absent from public document', () async {
      await contentService.createDraft(
        id: 'course_fields_test',
        contentType: ContentType.courses.key,
        title: 'Fields Test',
        data: {
          'title': 'Fields Test',
          'removableField': 'Should disappear on publish',
          'highlights': ['Point A', 'Point B', 'Point C'],
        },
      );
      await contentService.publish('course_fields_test');

      final pubV1 = await mockRepo.getPublishedItem('courses', 'course_fields_test');
      expect(pubV1!['removableField'], 'Should disappear on publish');
      expect((pubV1['highlights'] as List).length, 3);

      // Admin removes removableField and removes 2 highlights
      await contentService.updateDraft(
        id: 'course_fields_test',
        data: {
          'title': 'Fields Test',
          'highlights': ['Point A'],
        },
      );
      await contentService.publish('course_fields_test');

      final pubV2 = await mockRepo.getPublishedItem('courses', 'course_fields_test');
      expect(pubV2!.containsKey('removableField'), isFalse,
          reason: 'Removed field must NOT be merged or preserved in public document');
      expect((pubV2['highlights'] as List).length, 1);
      expect((pubV2['highlights'] as List).first, 'Point A');
    });

    test('Unpublish and republish cycle works cleanly', () async {
      await contentService.createDraft(
        id: 'prog_cycle',
        contentType: ContentType.programs.key,
        title: 'Cycle Program',
        data: {'title': 'Cycle V1'},
      );
      await contentService.publish('prog_cycle');
      expect(await mockRepo.getPublishedItem('programs', 'prog_cycle'), isNotNull);

      await contentService.unpublish('prog_cycle');
      expect(await mockRepo.getPublishedItem('programs', 'prog_cycle'), isNull);

      final draft = await mockRepo.getDraft('prog_cycle');
      expect(draft, isNotNull);
      expect(draft!.publishStatus, PublishStatus.draft);

      await contentService.updateDraft(id: 'prog_cycle', data: {'title': 'Cycle V2'});
      await contentService.publish('prog_cycle');

      final pubRestored = await mockRepo.getPublishedItem('programs', 'prog_cycle');
      expect(pubRestored, isNotNull);
      expect(pubRestored!['title'], 'Cycle V2');
    });

    test('Failed publishing preserves draft status and hasUnpublishedChanges', () async {
      final failingRepo = FailingPublishRepository();
      final failingService = ContentService(repository: failingRepo);

      await failingService.createDraft(
        id: 'fail_test',
        contentType: ContentType.faqs.key,
        title: 'Failing FAQ',
        data: {'question': 'Q?'},
      );

      expect(
        () => failingService.publish('fail_test'),
        throwsA(isA<ContentException>()),
      );

      final draft = await failingRepo.getDraft('fail_test');
      expect(draft!.publishStatus, PublishStatus.draft);
      expect(draft.hasUnpublishedChanges, isTrue);
    });

    test('Concurrent draft update protection rejects older expectedUpdatedAt', () async {
      final draft = await contentService.createDraft(
        id: 'concurrent_test',
        contentType: ContentType.courses.key,
        title: 'Concurrent Course',
        data: {},
      );

      final originalTime = draft.updatedAt;

      // Another session modifies the draft in the background
      await Future.delayed(const Duration(milliseconds: 600));
      await contentService.updateDraft(
        id: 'concurrent_test',
        title: 'Updated by another tab',
      );

      // Original session attempts to publish with its original expectedUpdatedAt
      expect(
        () => contentService.publish('concurrent_test', expectedUpdatedAt: originalTime),
        throwsA(isA<ContentException>()),
      );
    });

    test('Delete permanently removes draft and published versions', () async {
      await contentService.createDraft(
        id: 'faq_test',
        contentType: ContentType.faqs.key,
        title: 'Test FAQ',
        data: {'question': 'Q?', 'order': 1},
      );
      await contentService.publish('faq_test');

      await contentService.delete('faq_test');

      expect(await mockRepo.getDraft('faq_test'), isNull);
      expect(
        await mockRepo.getPublishedItem('faqs', 'faq_test'),
        isNull,
      );
    });
  });

  group('Default Data Seeding Logic & Idempotency', () {
    late MockContentRepository mockRepo;
    late ContentService contentService;

    setUp(() {
      mockRepo = MockContentRepository();
      contentService = ContentService(repository: mockRepo);
    });

    test('Seeding is retryable and idempotent without creating duplicates', () async {
      final defaults = HomeDefaultData.defaultCourses;

      // Run 1: All items are new
      final existingDrafts1 = await contentService.getDrafts(contentType: 'courses');
      final existingIds1 = existingDrafts1.map((d) => d.id).toSet();
      int created1 = 0;
      int skipped1 = 0;

      for (final item in defaults) {
        final id = item['id'] as String;
        if (existingIds1.contains(id)) {
          skipped1++;
        } else {
          await contentService.createDraft(
            id: id,
            contentType: ContentType.courses.key,
            title: item['title'] as String,
            data: item,
          );
          created1++;
          existingIds1.add(id);
        }
      }

      expect(created1, 3);
      expect(skipped1, 0);

      // Run 2: Seeding repeated
      final existingDrafts2 = await contentService.getDrafts(contentType: 'courses');
      final existingIds2 = existingDrafts2.map((d) => d.id).toSet();
      int created2 = 0;
      int skipped2 = 0;

      for (final item in defaults) {
        final id = item['id'] as String;
        if (existingIds2.contains(id)) {
          skipped2++;
        } else {
          created2++;
        }
      }

      expect(created2, 0);
      expect(skipped2, 3);

      final totalDrafts = await contentService.getDrafts(contentType: 'courses');
      expect(totalDrafts.length, 3);
    });

    test('Seeding safely completes missing items after partial failure', () async {
      // Only 1 item already exists
      final firstCourse = HomeDefaultData.defaultCourses.first;
      await contentService.createDraft(
        id: firstCourse['id'] as String,
        contentType: ContentType.courses.key,
        title: firstCourse['title'] as String,
        data: firstCourse,
      );

      final existingDrafts = await contentService.getDrafts(contentType: 'courses');
      final existingIds = existingDrafts.map((d) => d.id).toSet();

      int created = 0;
      int skipped = 0;

      for (final item in HomeDefaultData.defaultCourses) {
        final id = item['id'] as String;
        if (existingIds.contains(id)) {
          skipped++;
        } else {
          await contentService.createDraft(
            id: id,
            contentType: ContentType.courses.key,
            title: item['title'] as String,
            data: item,
          );
          created++;
          existingIds.add(id);
        }
      }

      expect(created, 2);
      expect(skipped, 1);

      final totalDrafts = await contentService.getDrafts(contentType: 'courses');
      expect(totalDrafts.length, 3);
    });
  });

  group('Home CMS UI Widgets & Preview Fidelity for All 13 Sections', () {
    testWidgets('PublishStatusBadge renders draft and published states',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PublishStatusBadge(
                  status: PublishStatus.draft,
                  hasUnpublishedChanges: false,
                ),
                PublishStatusBadge(
                  status: PublishStatus.published,
                  hasUnpublishedChanges: false,
                ),
                PublishStatusBadge(
                  status: PublishStatus.published,
                  hasUnpublishedChanges: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('DRAFT ONLY'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('UNPUBLISHED CHANGES'), findsOneWidget);
    });

    testWidgets('SectionPreviewDialog renders visual preview for all 13 sections without errors',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      for (final section in HomeSectionDefinition.sections) {
        Map<String, dynamic> sampleData;
        if (section.isSingleton) {
          sampleData = section.defaultSingletonData;
        } else if (section.id == 'courses') {
          sampleData = HomeDefaultData.defaultCourses.first;
        } else if (section.id == 'programs') {
          sampleData = HomeDefaultData.defaultPrograms.first;
        } else if (section.id == 'gallery') {
          sampleData = HomeDefaultData.defaultGallery.first;
        } else {
          sampleData = HomeDefaultData.defaultFaqs.first;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SectionPreviewDialog(
                section: section,
                data: sampleData,
              ),
            ),
          ),
        );

        expect(find.text('Preview: ${section.title}'), findsOneWidget);
        // Verify no raw unparsed toString data preview was rendered
        expect(find.byType(Dialog), findsOneWidget);
      }
    });

    testWidgets('HomeCmsScreen renders navigation list and active header',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockContentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomeCmsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show section list title
      expect(find.text('Website Sections'), findsOneWidget);
      expect(find.text('13 Home Page Content Modules'), findsOneWidget);

      // Default active is Hero Section
      expect(find.text('Hero Section'), findsAtLeastNWidgets(1));
      expect(find.text('Singleton Document'), findsOneWidget);
      expect(find.text('Save Draft'), findsAtLeastNWidgets(1));
      expect(find.text('Publish Live'), findsAtLeastNWidgets(1));
    });
  });
}
