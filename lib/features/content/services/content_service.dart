import 'package:firebase_auth/firebase_auth.dart';
import '../data/content_repository.dart';
import '../models/cms_content_item.dart';
import '../models/publish_status.dart';

/// Exception thrown for content management and publishing failures.
class ContentException implements Exception {
  final String message;
  final String? code;

  const ContentException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Service orchestrating content lifecycle operations with input validation
/// and user auditing.
class ContentService {
  final ContentRepository repository;
  final FirebaseAuth? auth;
  final String? explicitAdminUser;

  ContentService({
    required this.repository,
    this.auth,
    this.explicitAdminUser,
  });

  String? get _currentAdminUser {
    if (explicitAdminUser != null) return explicitAdminUser;
    try {
      final resolvedAuth = auth ?? FirebaseAuth.instance;
      return resolvedAuth.currentUser?.email ?? resolvedAuth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Fetches drafts from the repository.
  Future<List<CmsContentItem>> getDrafts({String? contentType}) async {
    try {
      return await repository.getDrafts(contentType: contentType);
    } catch (e) {
      throw ContentException('Failed to load content: ${e.toString()}');
    }
  }

  /// Fetches a single draft by [id].
  Future<CmsContentItem?> getDraft(String id) async {
    try {
      return await repository.getDraft(id);
    } catch (e) {
      throw ContentException('Failed to load item: ${e.toString()}');
    }
  }

  /// Fetches the currently live public version of an item.
  Future<Map<String, dynamic>?> getPublishedItem(
    String contentType,
    String id,
  ) async {
    try {
      return await repository.getPublishedItem(contentType, id);
    } catch (e) {
      throw ContentException(
        'Failed to load published version: ${e.toString()}',
      );
    }
  }

  /// Creates a brand-new content draft.
  Future<CmsContentItem> createDraft({
    required String id,
    required String contentType,
    required String title,
    required Map<String, dynamic> data,
  }) async {
    final cleanId = id.trim().toLowerCase().replaceAll(' ', '_');
    if (cleanId.isEmpty) {
      throw const ContentException('Document ID cannot be empty.');
    }
    if (title.trim().isEmpty) {
      throw const ContentException('Title cannot be empty.');
    }

    try {
      final existing = await repository.getDraft(cleanId);
      if (existing != null) {
        throw ContentException(
          'An item with ID "$cleanId" already exists in drafts.',
        );
      }

      final now = DateTime.now();
      final draft = CmsContentItem(
        id: cleanId,
        contentType: contentType,
        title: title.trim(),
        data: data,
        publishStatus: PublishStatus.draft,
        hasUnpublishedChanges: true,
        createdAt: now,
        updatedAt: now,
        lastEditedBy: _currentAdminUser,
      );

      await repository.saveDraft(draft);
      return draft;
    } on ContentException {
      rethrow;
    } catch (e) {
      throw ContentException('Failed to create draft: ${e.toString()}');
    }
  }

  /// Updates an existing draft's data.
  ///
  /// Important: If the item is already published, this modifies ONLY the draft
  /// copy, preserving the live published version on the website.
  Future<CmsContentItem> updateDraft({
    required String id,
    String? title,
    Map<String, dynamic>? data,
  }) async {
    try {
      final existing = await repository.getDraft(id);
      if (existing == null) {
        throw ContentException('Cannot update: item "$id" does not exist.');
      }

      final updated = existing.copyWith(
        title: title != null && title.trim().isNotEmpty ? title.trim() : null,
        data: data,
        hasUnpublishedChanges: true,
        updatedAt: DateTime.now(),
        lastEditedBy: _currentAdminUser,
      );

      await repository.saveDraft(updated);
      return updated;
    } on ContentException {
      rethrow;
    } catch (e) {
      throw ContentException('Failed to update draft: ${e.toString()}');
    }
  }

  /// Publishes draft changes to the public website collection atomically.
  Future<void> publish(String draftId) async {
    try {
      await repository.publish(draftId);
    } catch (e) {
      throw ContentException('Failed to publish content: ${e.toString()}');
    }
  }

  /// Unpublishes live content from the public website while preserving the draft.
  Future<void> unpublish(String draftId) async {
    try {
      await repository.unpublish(draftId);
    } catch (e) {
      throw ContentException('Failed to unpublish content: ${e.toString()}');
    }
  }

  /// Permanently removes content from drafts and public website.
  Future<void> delete(String draftId) async {
    try {
      await repository.delete(draftId);
    } catch (e) {
      throw ContentException('Failed to delete content: ${e.toString()}');
    }
  }
}
