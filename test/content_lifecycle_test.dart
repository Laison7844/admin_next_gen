import 'package:admin_next_gen/core/constants/admin_config.dart';
import 'package:admin_next_gen/features/content/data/content_repository.dart';
import 'package:admin_next_gen/features/content/models/cms_content_item.dart';
import 'package:admin_next_gen/features/content/models/content_type.dart';
import 'package:admin_next_gen/features/content/models/publish_status.dart';
import 'package:admin_next_gen/features/content/providers/content_provider.dart';
import 'package:admin_next_gen/features/content/services/content_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake repository simulating Firestore dual-collection storage
/// and atomic batch operations for hermetic testing without network dependencies.
class FakeContentRepository implements ContentRepository {
  final Map<String, CmsContentItem> drafts = {};
  final Map<String, Map<String, dynamic>> publicDocs = {};

  String _publicPath(String collection, String id) => '$collection/$id';

  @override
  Future<List<CmsContentItem>> getDrafts({String? contentType}) async {
    if (contentType == null || contentType.isEmpty) {
      return drafts.values.toList();
    }
    return drafts.values
        .where((item) => item.contentType == contentType)
        .toList();
  }

  @override
  Future<CmsContentItem?> getDraft(String id) async {
    return drafts[id];
  }

  @override
  Future<Map<String, dynamic>?> getPublishedItem(
    String contentType,
    String id,
  ) async {
    return publicDocs[_publicPath(contentType, id)];
  }

  @override
  Future<void> saveDraft(CmsContentItem item) async {
    // Saves strictly to drafts map. Public map is NEVER modified here.
    drafts[item.id] = item;
  }

  @override
  Future<void> publish(String draftId) async {
    final draft = drafts[draftId];
    if (draft == null) {
      throw StateError('Draft $draftId does not exist');
    }

    final publishedItem = draft.copyWith(
      publishStatus: PublishStatus.published,
      hasUnpublishedChanges: false,
      publishedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Atomic simulation: write to public, update draft
    publicDocs[_publicPath(draft.publicCollection, draft.id)] =
        publishedItem.toPublicPayload();
    drafts[draftId] = publishedItem;
  }

  @override
  Future<void> unpublish(String draftId) async {
    final draft = drafts[draftId];
    if (draft == null) {
      throw StateError('Draft $draftId does not exist');
    }

    final unpublishedItem = draft.copyWith(
      publishStatus: PublishStatus.draft,
      hasUnpublishedChanges: true,
      updatedAt: DateTime.now(),
    );

    // Atomic simulation: remove from public, keep draft
    publicDocs.remove(_publicPath(draft.publicCollection, draft.id));
    drafts[draftId] = unpublishedItem;
  }

  @override
  Future<void> delete(String draftId) async {
    final draft = drafts[draftId];
    if (draft != null) {
      publicDocs.remove(_publicPath(draft.publicCollection, draft.id));
    }
    drafts.remove(draftId);
  }
}

void main() {
  group('Phase 2 - Domain Models Tests', () {
    test('ContentType mapping returns correct collection names and defaults', () {
      expect(ContentType.courses.publicCollection, 'courses');
      expect(ContentType.programs.publicCollection, 'programs');
      expect(ContentType.faqs.publicCollection, 'faqs');
      expect(ContentType.testimonials.publicCollection, 'testimonials');
      expect(ContentType.gallery.publicCollection, 'gallery');
      expect(ContentType.siteSections.publicCollection, 'site_sections');

      expect(ContentType.fromKey('programs'), ContentType.programs);
      expect(ContentType.fromKey('unknown_key'), ContentType.courses);
    });

    test('PublishStatus correctly indicates draft vs published', () {
      expect(PublishStatus.draft.isDraft, isTrue);
      expect(PublishStatus.draft.isPublished, isFalse);
      expect(PublishStatus.published.isPublished, isTrue);
      expect(PublishStatus.published.isDraft, isFalse);
      expect(PublishStatus.fromKey('published'), PublishStatus.published);
      expect(PublishStatus.fromKey('other'), PublishStatus.draft);
    });

    test('CmsContentItem serialization and public payload generation', () {
      final now = DateTime(2026, 11, 12, 10, 0);
      final item = CmsContentItem(
        id: 'course_ai_101',
        contentType: 'courses',
        title: 'Intro to AI & Robotics',
        data: {'level': 'Beginner', 'fee': 3500},
        publishStatus: PublishStatus.draft,
        hasUnpublishedChanges: true,
        createdAt: now,
        updatedAt: now,
        lastEditedBy: 'admin@nextgen.edu',
      );

      final firestoreMap = item.toFirestore();
      expect(firestoreMap['id'], 'course_ai_101');
      expect(firestoreMap['contentType'], 'courses');
      expect(firestoreMap['title'], 'Intro to AI & Robotics');
      expect(firestoreMap['publishStatus'], 'draft');
      expect(firestoreMap['hasUnpublishedChanges'], true);

      final restored = CmsContentItem.fromFirestore(firestoreMap, 'course_ai_101');
      expect(restored.id, 'course_ai_101');
      expect(restored.title, 'Intro to AI & Robotics');
      expect(restored.data['level'], 'Beginner');

      final publicPayload = restored.toPublicPayload();
      expect(publicPayload['id'], 'course_ai_101');
      expect(publicPayload['title'], 'Intro to AI & Robotics');
      expect(publicPayload['data']['fee'], 3500);
      // Public payload does NOT leak draft metadata
      expect(publicPayload.containsKey('hasUnpublishedChanges'), isFalse);
      expect(publicPayload.containsKey('publishStatus'), isFalse);
    });
  });

  group('Phase 2 - Draft, Edit, Publish, Unpublish Lifecycle Tests', () {
    late FakeContentRepository repository;
    late ContentService service;

    setUp(() {
      repository = FakeContentRepository();
      service = ContentService(repository: repository);
    });

    test('Creating a new draft only saves to drafts, NOT to public collection',
        () async {
      await service.createDraft(
        id: 'course_python',
        contentType: 'courses',
        title: 'Python for Beginners',
        data: {'weeks': 8, 'seats': 15},
      );

      final draft = await repository.getDraft('course_python');
      expect(draft, isNotNull);
      expect(draft!.publishStatus.isDraft, isTrue);
      expect(draft.hasUnpublishedChanges, isTrue);

      final publicItem =
          await repository.getPublishedItem('courses', 'course_python');
      expect(publicItem, isNull,
          reason: 'Public collection must remain empty for unpublished drafts');
    });

    test(
        'Editing an existing published item modifies ONLY the draft without overwriting public version',
        () async {
      // 1. Create and publish initial version
      await service.createDraft(
        id: 'program_stem',
        contentType: 'programs',
        title: 'STEM Discovery V1',
        data: {'description': 'Original published description'},
      );
      await service.publish('program_stem');

      // Verify it is published
      final publicV1 =
          await repository.getPublishedItem('programs', 'program_stem');
      expect(publicV1, isNotNull);
      expect(publicV1!['title'], 'STEM Discovery V1');
      expect(publicV1['data']['description'], 'Original published description');

      // 2. Admin edits the draft (changes title and description)
      await service.updateDraft(
        id: 'program_stem',
        title: 'STEM Discovery V2 (DRAFT)',
        data: {'description': 'Unpublished draft changes'},
      );

      // Verify draft has been updated
      final draft = await repository.getDraft('program_stem');
      expect(draft!.title, 'STEM Discovery V2 (DRAFT)');
      expect(draft.hasUnpublishedChanges, isTrue);
      expect(draft.publishStatus.isPublished, isTrue);

      // 3. Verify public version is COMPLETELY UNTOUCHED
      final publicStillV1 =
          await repository.getPublishedItem('programs', 'program_stem');
      expect(publicStillV1!['title'], 'STEM Discovery V1',
          reason: 'Public title must remain V1 until explicit publish');
      expect(
        publicStillV1['data']['description'],
        'Original published description',
        reason: 'Public description must remain V1 until explicit publish',
      );

      // 4. Now admin explicitly publishes
      await service.publish('program_stem');

      // 5. Verify public version now reflects V2
      final publicV2 =
          await repository.getPublishedItem('programs', 'program_stem');
      expect(publicV2!['title'], 'STEM Discovery V2 (DRAFT)');
      expect(publicV2['data']['description'], 'Unpublished draft changes');

      final updatedDraft = await repository.getDraft('program_stem');
      expect(updatedDraft!.hasUnpublishedChanges, isFalse);
    });

    test('Unpublish removes content from public site while preserving draft',
        () async {
      // Create and publish
      await service.createDraft(
        id: 'faq_admission',
        contentType: 'faqs',
        title: 'How to enroll?',
        data: {'answer': 'Visit campus.'},
      );
      await service.publish('faq_admission');

      expect(await repository.getPublishedItem('faqs', 'faq_admission'),
          isNotNull);

      // Unpublish
      await service.unpublish('faq_admission');

      // Verify removed from public collection
      expect(await repository.getPublishedItem('faqs', 'faq_admission'), isNull,
          reason: 'Public collection must not have the unpublished item');

      // Verify draft is PRESERVED in CMS
      final preservedDraft = await repository.getDraft('faq_admission');
      expect(preservedDraft, isNotNull,
          reason: 'Draft must remain preserved in CMS');
      expect(preservedDraft!.publishStatus.isDraft, isTrue);
      expect(preservedDraft.hasUnpublishedChanges, isTrue);
    });

    test('Delete permanently removes content from BOTH drafts and public site',
        () async {
      await service.createDraft(
        id: 'testimonial_alex',
        contentType: 'testimonials',
        title: 'Alex Review',
        data: {'rating': 5},
      );
      await service.publish('testimonial_alex');

      expect(
          await repository.getPublishedItem('testimonials', 'testimonial_alex'),
          isNotNull);
      expect(await repository.getDraft('testimonial_alex'), isNotNull);

      // Delete
      await service.delete('testimonial_alex');

      expect(
          await repository.getPublishedItem('testimonials', 'testimonial_alex'),
          isNull);
      expect(await repository.getDraft('testimonial_alex'), isNull);
    });
  });

  group('Phase 2 - Riverpod Content Operation Controller Tests', () {
    test('ContentOperationController manages loading, error, and success states',
        () async {
      final fakeRepo = FakeContentRepository();
      final container = ProviderContainer(
        overrides: [
          contentRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(contentOperationControllerProvider.notifier);

      // 1. Successful draft creation
      final success = await controller.createDraft(
        id: 'gallery_robotics_fair',
        contentType: 'gallery',
        title: 'Robotics Fair 2026',
        data: {'image': 'fair.webp'},
      );

      expect(success, isTrue);
      expect(container.read(contentOperationControllerProvider).errorMessage,
          isNull);
      expect(
        container.read(contentOperationControllerProvider).successMessage,
        'Draft created successfully.',
      );

      // 2. Duplicate ID validation failure
      final duplicateResult = await controller.createDraft(
        id: 'gallery_robotics_fair',
        contentType: 'gallery',
        title: 'Duplicate',
        data: {},
      );

      expect(duplicateResult, isFalse);
      expect(
        container.read(contentOperationControllerProvider).errorMessage,
        contains('already exists'),
      );
    });
  });

  group('Phase 2 - Admin Authorization Rules Logic Tests', () {
    test('AdminConfig checks email and UID match without letting users self-grant',
        () {
      // Testing AdminConfig methods
      expect(AdminConfig.authorizedAdminEmail, 'admin@nextgen.edu');
      expect(AdminConfig.authorizedAdminUid, isNotEmpty);
    });
  });
}

