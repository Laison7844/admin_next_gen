import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_repository.dart';
import '../models/cms_content_item.dart';
import '../services/content_service.dart';

/// Provider for the content repository.
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return FirestoreContentRepository();
});

/// Provider for the content service.
final contentServiceProvider = Provider<ContentService>((ref) {
  final repository = ref.watch(contentRepositoryProvider);
  return ContentService(repository: repository);
});

/// One-time fetch provider for list of content drafts (filtered by contentType).
/// Uses FutureProvider rather than a continuous StreamProvider to prioritize
/// staying within Firebase free allowances and avoid redundant listener reads.
final contentListProvider =
    FutureProvider.family<List<CmsContentItem>, String?>((ref, contentType) {
  final service = ref.watch(contentServiceProvider);
  return service.getDrafts(contentType: contentType);
});

/// One-time fetch provider for a single draft by [id].
final contentItemProvider =
    FutureProvider.family<CmsContentItem?, String>((ref, id) {
  final service = ref.watch(contentServiceProvider);
  return service.getDraft(id);
});

/// One-time fetch provider returning the set of actual live document IDs
/// currently present in public Firestore collections.
final publishedDocIdsProvider =
    FutureProvider<Map<String, Set<String>>>((ref) async {
  final service = ref.watch(contentServiceProvider);
  const collections = [
    'courses',
    'programs',
    'testimonials',
    'gallery',
    'faqs',
    'site_sections',
  ];

  final results = await Future.wait(
    collections.map((col) => service.getPublishedDocIds(col)),
  );

  return Map.fromIterables(collections, results);
});

/// State of content mutation operations (publish, unpublish, save, delete).
class ContentOperationState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ContentOperationState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ContentOperationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ContentOperationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Controller managing content lifecycle actions and mutation states.
class ContentOperationController extends StateNotifier<ContentOperationState> {
  final ContentService _service;
  final Ref _ref;

  ContentOperationController(this._service, this._ref)
      : super(const ContentOperationState());

  void clearMessages() {
    state = const ContentOperationState();
  }

  Future<bool> createDraft({
    required String id,
    required String contentType,
    required String title,
    required Map<String, dynamic> data,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _service.createDraft(
        id: id,
        contentType: contentType,
        title: title,
        data: data,
      );
      _ref.invalidate(contentListProvider);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Draft created successfully.',
      );
      return true;
    } on ContentException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred while creating draft.',
      );
      return false;
    }
  }

  Future<bool> saveDraft({
    required String id,
    required String contentType,
    required String title,
    required Map<String, dynamic> data,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final existing = await _service.getDraft(id);
      if (existing == null) {
        await _service.createDraft(
          id: id,
          contentType: contentType,
          title: title,
          data: data,
        );
      } else {
        await _service.updateDraft(
          id: id,
          title: title,
          data: data,
        );
      }
      _ref.invalidate(contentListProvider(contentType));
      _ref.invalidate(contentItemProvider(id));
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Draft saved successfully.',
      );
      return true;
    } on ContentException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred while saving draft.',
      );
      return false;
    }
  }

  Future<bool> updateDraft({
    required String id,
    String? title,
    Map<String, dynamic>? data,
    String? contentType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _service.updateDraft(id: id, title: title, data: data);
      _ref.invalidate(contentListProvider(contentType));
      _ref.invalidate(contentItemProvider(id));
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Draft saved successfully.',
      );
      return true;
    } on ContentException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred while saving draft.',
      );
      return false;
    }
  }

  Future<bool> publish({
    required String draftId,
    String? contentType,
    DateTime? expectedUpdatedAt,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _service.publish(draftId, expectedUpdatedAt: expectedUpdatedAt);
      _ref.invalidate(contentListProvider(contentType));
      _ref.invalidate(contentItemProvider(draftId));
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Content published to live website.',
      );
      return true;
    } on ContentException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to publish content to live website.',
      );
      return false;
    }
  }

  Future<bool> unpublish({
    required String draftId,
    String? contentType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _service.unpublish(draftId);
      _ref.invalidate(contentListProvider(contentType));
      _ref.invalidate(contentItemProvider(draftId));
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Content unpublished from live website.',
      );
      return true;
    } on ContentException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to unpublish content.',
      );
      return false;
    }
  }

  Future<bool> delete({
    required String draftId,
    String? contentType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _service.delete(draftId);
      _ref.invalidate(contentListProvider(contentType));
      _ref.invalidate(contentItemProvider(draftId));
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Content permanently deleted.',
      );
      return true;
    } on ContentException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete content.',
      );
      return false;
    }
  }
}

/// Provider for content operations controller.
final contentOperationControllerProvider = StateNotifierProvider<
    ContentOperationController, ContentOperationState>((ref) {
  final service = ref.watch(contentServiceProvider);
  return ContentOperationController(service, ref);
});

