import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/content/data/content_repository.dart';
import 'package:admin_next_gen/features/content/models/cms_content_item.dart';
import 'package:admin_next_gen/features/content/models/publish_status.dart';
import 'package:admin_next_gen/features/content/providers/content_provider.dart';
import 'package:admin_next_gen/features/testimonials/data/testimonial_repository.dart';
import 'package:admin_next_gen/features/testimonials/models/testimonial_item.dart';
import 'package:admin_next_gen/features/testimonials/presentation/testimonials_screen.dart';
import 'package:admin_next_gen/features/testimonials/presentation/widgets/testimonial_editor_dialog.dart';
import 'package:admin_next_gen/features/testimonials/presentation/widgets/testimonial_preview_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake repository simulating Firestore dual-collection storage
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
  Future<CmsContentItem?> getDraft(String id) async => drafts[id];

  @override
  Future<Map<String, dynamic>?> getPublishedItem(
    String contentType,
    String id,
  ) async {
    return publicDocs[_publicPath(contentType, id)];
  }

  @override
  Future<void> saveDraft(CmsContentItem item) async {
    drafts[item.id] = item;
  }

  @override
  Future<void> publish(String draftId, {DateTime? expectedUpdatedAt}) async {
    final draft = drafts[draftId];
    if (draft == null) {
      throw StateError('Draft $draftId does not exist');
    }

    final now = DateTime.now();
    final publishedItem = draft.copyWith(
      publishStatus: PublishStatus.published,
      hasUnpublishedChanges: false,
      publishedAt: now,
      updatedAt: now,
    );

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

    publicDocs.remove(_publicPath(draft.publicCollection, draft.id));
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
      publicDocs.remove(_publicPath(draft.publicCollection, draft.id));
    }
    drafts.remove(draftId);
  }

  @override
  Future<Set<String>> getPublishedDocIds(String contentType) async {
    final prefix = '$contentType/';
    return publicDocs.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .toSet();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  group('TestimonialItem Model Tests', () {
    test('Round-trips between TestimonialItem and CmsContentItem', () {
      final now = DateTime.now();
      final item = TestimonialItem(
        id: 'test_1',
        personName: 'Aarav Sharma',
        role: 'Student',
        program: 'Class 10 Board Excellence',
        testimonialText: 'NextGen Academy completely transformed my learning habits!',
        profileImage: 'https://storage.googleapis.com/test/aarav.jpg',
        rating: 5,
        isFeatured: true,
        displayOrder: 1,
        isPublished: true,
        hasUnpublishedChanges: false,
        createdAt: now,
        updatedAt: now,
        publishedAt: now,
      );

      final cmsItem = item.toCmsContentItem();
      expect(cmsItem.id, 'test_1');
      expect(cmsItem.contentType, 'testimonials');
      expect(cmsItem.title, 'Aarav Sharma');
      expect(cmsItem.publishStatus, PublishStatus.published);
      expect(cmsItem.hasUnpublishedChanges, isFalse);

      final reconstructed = TestimonialItem.fromCmsContentItem(cmsItem);
      expect(reconstructed.id, 'test_1');
      expect(reconstructed.personName, 'Aarav Sharma');
      expect(reconstructed.role, 'Student');
      expect(reconstructed.program, 'Class 10 Board Excellence');
      expect(reconstructed.rating, 5);
      expect(reconstructed.isFeatured, isTrue);
      expect(reconstructed.displayOrder, 1);
      expect(reconstructed.isPublished, isTrue);
      expect(reconstructed.profileImage, 'https://storage.googleapis.com/test/aarav.jpg');
    });

    test('Parses both flat maps and nested data envelopes safely', () {
      final flatDoc = {
        'id': 'test_flat',
        'personName': 'Priya Patel',
        'role': 'Parent',
        'program': 'Foundation Class 9',
        'testimonialText': 'Dedicated mentors and clear progress feedback.',
        'rating': '4',
        'isFeatured': 'true',
        'displayOrder': '2',
        'publishStatus': 'published',
        'createdAt': Timestamp.now(),
      };

      final parsedFlat = TestimonialItem.fromMap(flatDoc);
      expect(parsedFlat.id, 'test_flat');
      expect(parsedFlat.personName, 'Priya Patel');
      expect(parsedFlat.role, 'Parent');
      expect(parsedFlat.rating, 4);
      expect(parsedFlat.isFeatured, isTrue);
      expect(parsedFlat.displayOrder, 2);
      expect(parsedFlat.isPublished, isTrue);

      final nestedDoc = {
        'id': 'test_nested',
        'title': 'Rohan Verma',
        'publishStatus': 'draft',
        'hasUnpublishedChanges': true,
        'data': {
          'personName': 'Rohan Verma',
          'role': 'Alumni',
          'testimonialText': 'Cracked JEE with top percentile!',
          'rating': 5,
          'isFeatured': false,
          'displayOrder': 3,
        },
      };

      final parsedNested = TestimonialItem.fromMap(nestedDoc);
      expect(parsedNested.id, 'test_nested');
      expect(parsedNested.personName, 'Rohan Verma');
      expect(parsedNested.role, 'Alumni');
      expect(parsedNested.isFeatured, isFalse);
      expect(parsedNested.isPublished, isFalse);
    });

    test('Clamps rating between 1 and 5', () {
      final low = TestimonialItem.fromMap({'rating': -2});
      expect(low.rating, 1);

      final high = TestimonialItem.fromMap({'rating': 10});
      expect(high.rating, 5);
    });

    test('toPublicPayload guarantees isPublished: true at root and data levels', () {
      final now = DateTime.now();
      final item = TestimonialItem(
        id: 'pub_test',
        personName: 'Ravi Kumar',
        role: 'Parent',
        testimonialText: 'Superb faculty.',
        rating: 5,
        displayOrder: 1,
        isPublished: true,
        createdAt: now,
        updatedAt: now,
      );

      final cmsItem = item.toCmsContentItem();
      final publicPayload = cmsItem.toPublicPayload();

      expect(publicPayload['isPublished'], isTrue);
      expect((publicPayload['data'] as Map<String, dynamic>)['isPublished'], isTrue);
      expect(publicPayload['id'], 'pub_test');
      expect(publicPayload['title'], 'Ravi Kumar');
    });
  });

  group('Testimonial Repository Lifecycle Tests', () {
    late FakeContentRepository fakeContentRepo;
    late FirestoreTestimonialRepository repository;

    setUp(() {
      fakeContentRepo = FakeContentRepository();
      repository = FirestoreTestimonialRepository(contentRepo: fakeContentRepo);
    });

    test('Saves draft, publishes live, unpublishes, and deletes', () async {
      final now = DateTime.now();
      final item = TestimonialItem(
        id: 'testimonial_101',
        personName: 'Sneha Roy',
        role: 'Student',
        program: 'Class 12 Physics',
        testimonialText: 'Concepts were taught thoroughly with clear real-world examples.',
        rating: 5,
        isFeatured: true,
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Save draft
      await repository.saveDraft(item);
      final draftsAfterSave = await repository.getTestimonials();
      expect(draftsAfterSave.length, 1);
      expect(draftsAfterSave.first.personName, 'Sneha Roy');
      expect(draftsAfterSave.first.isPublished, isFalse);
      // Public collection is completely untouched
      final publicDocBefore = await fakeContentRepo.getPublishedItem('testimonials', 'testimonial_101');
      expect(publicDocBefore, isNull);

      // 2. Publish
      await repository.publish('testimonial_101');
      final publishedDraft = await repository.getTestimonial('testimonial_101');
      expect(publishedDraft!.isPublished, isTrue);
      expect(publishedDraft.hasUnpublishedChanges, isFalse);

      final publicDocAfter = await fakeContentRepo.getPublishedItem('testimonials', 'testimonial_101');
      expect(publicDocAfter, isNotNull);
      expect(publicDocAfter!['id'], 'testimonial_101');
      expect(publicDocAfter['title'], 'Sneha Roy');

      // 3. Unpublish
      await repository.unpublish('testimonial_101');
      final draftAfterUnpublish = await repository.getTestimonial('testimonial_101');
      expect(draftAfterUnpublish!.isPublished, isFalse);
      expect(draftAfterUnpublish.hasUnpublishedChanges, isTrue);
      final publicDocUnpublished = await fakeContentRepo.getPublishedItem('testimonials', 'testimonial_101');
      expect(publicDocUnpublished, isNull);

      // 4. Delete
      await repository.delete('testimonial_101');
      final draftsAfterDelete = await repository.getTestimonials();
      expect(draftsAfterDelete.isEmpty, isTrue);
    });

    test('Editing published testimonial draft does not mutate public document until republished', () async {
      final now = DateTime.now();
      final item = TestimonialItem(
        id: 't_isolated',
        personName: 'Original Name',
        role: 'Student',
        testimonialText: 'Original text.',
        rating: 4,
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      // Save and publish
      await repository.saveDraft(item);
      await repository.publish('t_isolated');

      final publicBefore = await fakeContentRepo.getPublishedItem('testimonials', 't_isolated');
      expect(publicBefore!['title'], 'Original Name');
      expect(publicBefore['isPublished'], isTrue);

      // Edit draft only
      final updatedDraft = item.copyWith(
        personName: 'Modified Name',
        testimonialText: 'Modified text.',
        hasUnpublishedChanges: true,
      );
      await repository.saveDraft(updatedDraft);

      // Verify draft has changed
      final currentDraft = await repository.getTestimonial('t_isolated');
      expect(currentDraft!.personName, 'Modified Name');
      expect(currentDraft.hasUnpublishedChanges, isTrue);

      // Verify public document remains UNCHANGED
      final publicAfterDraftEdit = await fakeContentRepo.getPublishedItem('testimonials', 't_isolated');
      expect(publicAfterDraftEdit!['title'], 'Original Name');

      // Now republish and verify public document updates
      await repository.publish('t_isolated');
      final publicAfterRepublish = await fakeContentRepo.getPublishedItem('testimonials', 't_isolated');
      expect(publicAfterRepublish!['title'], 'Modified Name');
    });

    test('Sorts testimonials by displayOrder', () async {
      final now = DateTime.now();
      await repository.saveDraft(TestimonialItem(
        id: 't_3',
        personName: 'Charlie',
        role: 'Student',
        testimonialText: 'Great!',
        displayOrder: 3,
        createdAt: now,
        updatedAt: now,
      ));
      await repository.saveDraft(TestimonialItem(
        id: 't_1',
        personName: 'Alice',
        role: 'Student',
        testimonialText: 'Awesome!',
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      ));
      await repository.saveDraft(TestimonialItem(
        id: 't_2',
        personName: 'Bob',
        role: 'Parent',
        testimonialText: 'Excellent!',
        displayOrder: 2,
        createdAt: now,
        updatedAt: now,
      ));

      final items = await repository.getTestimonials();
      expect(items.map((i) => i.id).toList(), ['t_1', 't_2', 't_3']);
    });
  });

  group('TestimonialsScreen Widget Tests', () {
    late FakeContentRepository fakeContentRepo;

    setUp(() {
      fakeContentRepo = FakeContentRepository();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(fakeContentRepo),
        ],
        child: const MaterialApp(
          home: TestimonialsScreen(),
        ),
      );
    }

    testWidgets('Renders empty state with Add First Testimonial button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Testimonials'), findsOneWidget);
      expect(find.text('Total Testimonials'), findsOneWidget);
      expect(find.text('No testimonials added yet.'), findsOneWidget);
      expect(find.text('Add First Testimonial'), findsOneWidget);
    });

    testWidgets('Renders metric cards and testimonial items when data exists', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final now = DateTime.now();
      final item1 = TestimonialItem(
        id: 'item_1',
        personName: 'Aarav Sharma',
        role: 'Student',
        program: 'Class 10 Board Excellence',
        testimonialText: 'Top scores achieved thanks to NextGen.',
        rating: 5,
        isFeatured: true,
        displayOrder: 1,
        isPublished: true,
        hasUnpublishedChanges: false,
        createdAt: now,
        updatedAt: now,
      );
      final item2 = TestimonialItem(
        id: 'item_2',
        personName: 'Sunita Patel',
        role: 'Parent',
        program: 'Grade 9 Foundation',
        testimonialText: 'Caring teachers and very structured curriculum.',
        rating: 5,
        isFeatured: false,
        displayOrder: 2,
        isPublished: false,
        createdAt: now,
        updatedAt: now,
      );

      await fakeContentRepo.saveDraft(item1.toCmsContentItem());
      await fakeContentRepo.saveDraft(item2.toCmsContentItem());

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Sunita Patel'), findsOneWidget);
      expect(find.text('Featured'), findsWidgets);
      expect(find.text('Published'), findsWidgets);
      expect(find.text('Unpublished'), findsOneWidget);
    });

    testWidgets('Filters items by search query', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final now = DateTime.now();
      await fakeContentRepo.saveDraft(TestimonialItem(
        id: 'item_1',
        personName: 'Rohan Verma',
        role: 'Student',
        testimonialText: 'IIT JEE cracked with ease.',
        createdAt: now,
        updatedAt: now,
      ).toCmsContentItem());
      await fakeContentRepo.saveDraft(TestimonialItem(
        id: 'item_2',
        personName: 'Meera Sen',
        role: 'Parent',
        testimonialText: 'Very happy with daughter progress.',
        createdAt: now,
        updatedAt: now,
      ).toCmsContentItem());

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Rohan Verma'), findsOneWidget);
      expect(find.text('Meera Sen'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Rohan');
      await tester.pumpAndSettle();

      expect(find.text('Rohan Verma'), findsOneWidget);
      expect(find.text('Meera Sen'), findsNothing);
    });

    testWidgets('Opens TestimonialEditorDialog when Add Testimonial is pressed', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add First Testimonial'));
      await tester.pumpAndSettle();

      expect(find.text('New Testimonial'), findsOneWidget);
      expect(find.text('Person Name *'), findsOneWidget);
      expect(find.text('Testimonial Quote / Review *'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Save & Publish to Website'), findsOneWidget);
    });

    testWidgets('Validates required fields in editor dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TestimonialEditorDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Testimonial text is required'), findsOneWidget);
    });

    testWidgets('Opens TestimonialPreviewDialog and displays card correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final item = TestimonialItem(
        id: 'test_p',
        personName: 'Divya Nambiar',
        role: 'Alumni',
        program: 'Class 12 CBSE',
        testimonialText: 'Antigravity guidance helped me ace all competitive entrance exams!',
        rating: 5,
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestimonialPreviewDialog(testimonial: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Website Card Preview'), findsOneWidget);
      expect(find.text('Divya Nambiar'), findsOneWidget);
      expect(find.text('Alumni • Class 12 CBSE'), findsOneWidget);
      expect(find.text('"Antigravity guidance helped me ace all competitive entrance exams!"'), findsOneWidget);
      expect(find.text('Featured'), findsOneWidget);
      expect(find.text('Close Preview'), findsOneWidget);
    });
  });
}
