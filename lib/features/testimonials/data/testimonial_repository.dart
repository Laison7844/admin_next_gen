import '../../content/data/content_repository.dart';
import '../../content/models/content_type.dart';
import '../models/testimonial_item.dart';

/// Contract for testimonial content management in the CMS.
abstract class TestimonialRepository {
  /// Fetches all testimonial working drafts from `cms_drafts`.
  Future<List<TestimonialItem>> getTestimonials();

  /// Fetches a single testimonial item by its [id].
  Future<TestimonialItem?> getTestimonial(String id);

  /// Saves or updates a testimonial draft in `cms_drafts`.
  Future<void> saveDraft(TestimonialItem item);

  /// Atomically publishes a testimonial to the public `testimonials` collection
  /// and updates the draft's publishStatus.
  Future<void> publish(String id, {DateTime? expectedUpdatedAt});

  /// Atomically unpublishes a testimonial: removes it from the public `testimonials`
  /// collection while preserving the draft in `cms_drafts`.
  Future<void> unpublish(String id);

  /// Permanently removes a testimonial from both drafts and public collections.
  Future<void> delete(String id);

  /// Updates display order across multiple testimonials.
  Future<void> updateDisplayOrders(Map<String, int> orders);
}

/// Implementation of [TestimonialRepository] powered by [ContentRepository]
/// to guarantee consistent dual-collection semantics and atomic publishing transactions.
class FirestoreTestimonialRepository implements TestimonialRepository {
  final ContentRepository contentRepo;

  FirestoreTestimonialRepository({required this.contentRepo});

  @override
  Future<List<TestimonialItem>> getTestimonials() async {
    final drafts = await contentRepo.getDrafts(
      contentType: ContentType.testimonials.key,
    );

    final items = drafts.map((d) => TestimonialItem.fromCmsContentItem(d)).toList();
    items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return items;
  }

  @override
  Future<TestimonialItem?> getTestimonial(String id) async {
    final draft = await contentRepo.getDraft(id);
    if (draft == null) return null;
    return TestimonialItem.fromCmsContentItem(draft);
  }

  @override
  Future<void> saveDraft(TestimonialItem item) async {
    await contentRepo.saveDraft(item.toCmsContentItem());
  }

  @override
  Future<void> publish(String id, {DateTime? expectedUpdatedAt}) async {
    await contentRepo.publish(id, expectedUpdatedAt: expectedUpdatedAt);
  }

  @override
  Future<void> unpublish(String id) async {
    await contentRepo.unpublish(id);
  }

  @override
  Future<void> delete(String id) async {
    await contentRepo.delete(id);
  }

  @override
  Future<void> updateDisplayOrders(Map<String, int> orders) async {
    for (final entry in orders.entries) {
      final draft = await getTestimonial(entry.key);
      if (draft != null && draft.displayOrder != entry.value) {
        final updated = draft.copyWith(
          displayOrder: entry.value,
          updatedAt: DateTime.now(),
          hasUnpublishedChanges: true,
        );
        await saveDraft(updated);
      }
    }
  }
}
