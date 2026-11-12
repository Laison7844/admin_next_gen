import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cms_content_item.dart';
import '../models/publish_status.dart';

/// Abstract contract for CMS content operations.
abstract class ContentRepository {
  /// Retrieves working drafts from `cms_drafts`, optionally filtered by [contentType].
  /// Uses a one-time fetch to optimize cost and avoid unnecessary listeners.
  Future<List<CmsContentItem>> getDrafts({String? contentType});

  /// Retrieves a single draft item by its [id].
  Future<CmsContentItem?> getDraft(String id);

  /// Retrieves the current published version from the public collection if it exists.
  Future<Map<String, dynamic>?> getPublishedItem(String contentType, String id);

  /// Saves or updates a draft document in `cms_drafts/{id}`.
  /// If the item was already published, this does NOT touch the public collection.
  Future<void> saveDraft(CmsContentItem item);

  /// Atomically publishes content:
  /// 1. Copies `draft.data` into target public collection (e.g. `courses/{id}`).
  /// 2. Updates `cms_drafts/{id}` with `publishStatus = published` and
  ///    `hasUnpublishedChanges = false`.
  Future<void> publish(String draftId);

  /// Atomically unpublishes content:
  /// 1. Deletes document from public collection.
  /// 2. Updates `cms_drafts/{id}` with `publishStatus = draft` and
  ///    `hasUnpublishedChanges = true`.
  /// The draft is safely preserved in the CMS.
  Future<void> unpublish(String draftId);

  /// Permanently removes content:
  /// 1. Deletes public version from public collection if currently published.
  /// 2. Deletes draft from `cms_drafts/{id}`.
  Future<void> delete(String draftId);
}

/// Firestore implementation of [ContentRepository] enforcing the dual-collection
/// architecture and atomic publishing lifecycle.
class FirestoreContentRepository implements ContentRepository {
  static const String draftsCollection = 'cms_drafts';

  final FirebaseFirestore _firestore;

  FirestoreContentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<CmsContentItem>> getDrafts({String? contentType}) async {
    Query<Map<String, dynamic>> query = _firestore.collection(draftsCollection);

    if (contentType != null && contentType.isNotEmpty) {
      query = query.where('contentType', isEqualTo: contentType);
    }

    // Cost-conscious: one-time get() avoiding persistent real-time listener bandwidth.
    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return CmsContentItem.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  @override
  Future<CmsContentItem?> getDraft(String id) async {
    final doc = await _firestore.collection(draftsCollection).doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return CmsContentItem.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<Map<String, dynamic>?> getPublishedItem(
    String contentType,
    String id,
  ) async {
    final doc = await _firestore.collection(contentType).doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return doc.data();
  }

  @override
  Future<void> saveDraft(CmsContentItem item) async {
    final draftRef = _firestore.collection(draftsCollection).doc(item.id);

    // Save strictly to `cms_drafts`. Live public collection is completely untouched.
    await draftRef.set(
      item.toFirestore(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> publish(String draftId) async {
    final draft = await getDraft(draftId);
    if (draft == null) {
      throw StateError('Cannot publish draft: item "$draftId" does not exist.');
    }

    final publicCollection = draft.publicCollection;
    final publicDocRef = _firestore.collection(publicCollection).doc(draft.id);
    final draftDocRef = _firestore.collection(draftsCollection).doc(draft.id);

    final now = DateTime.now();

    final publishedItem = draft.copyWith(
      publishStatus: PublishStatus.published,
      hasUnpublishedChanges: false,
      publishedAt: now,
      updatedAt: now,
    );

    // Atomic batch write ensuring public doc and draft metadata update together
    final batch = _firestore.batch();

    // 1. Write clean payload to public collection
    batch.set(
      publicDocRef,
      publishedItem.toPublicPayload(),
      SetOptions(merge: true),
    );

    // 2. Update draft record
    batch.set(
      draftDocRef,
      publishedItem.toFirestore(),
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  @override
  Future<void> unpublish(String draftId) async {
    final draft = await getDraft(draftId);
    if (draft == null) {
      throw StateError('Cannot unpublish draft: item "$draftId" does not exist.');
    }

    final publicCollection = draft.publicCollection;
    final publicDocRef = _firestore.collection(publicCollection).doc(draft.id);
    final draftDocRef = _firestore.collection(draftsCollection).doc(draft.id);

    final now = DateTime.now();

    final updatedDraft = draft.copyWith(
      publishStatus: PublishStatus.draft,
      hasUnpublishedChanges: true,
      updatedAt: now,
    );

    // Atomic batch write
    final batch = _firestore.batch();

    // 1. Remove from public collection
    batch.delete(publicDocRef);

    // 2. Update draft record in CMS
    batch.set(
      draftDocRef,
      updatedDraft.toFirestore(),
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  @override
  Future<void> delete(String draftId) async {
    final draft = await getDraft(draftId);
    final draftDocRef = _firestore.collection(draftsCollection).doc(draftId);

    final batch = _firestore.batch();

    // 1. If item was published, remove public document
    if (draft != null && draft.publishStatus.isPublished) {
      final publicDocRef =
          _firestore.collection(draft.publicCollection).doc(draft.id);
      batch.delete(publicDocRef);
    }

    // 2. Remove draft from CMS
    batch.delete(draftDocRef);

    await batch.commit();
  }
}

