import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/admin_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/media_reference_repository.dart';
import '../data/media_repository.dart';
import '../models/media_item.dart';
import '../services/media_file_picker.dart';

/// Provider for fetching all media items from the repository.
final mediaListProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.getMediaItems();
});

/// Current active folder filter chip ('all', 'general', 'homepage', 'courses', 'programs', 'gallery').
final mediaFolderFilterProvider = StateProvider<String>((ref) => 'all');

/// Current search query string.
final mediaSearchQueryProvider = StateProvider<String>((ref) => '');

/// Computed provider that filters media by folder and search query.
final filteredMediaListProvider = Provider<AsyncValue<List<MediaItem>>>((ref) {
  final mediaAsync = ref.watch(mediaListProvider);
  final folder = ref.watch(mediaFolderFilterProvider).toLowerCase();
  final query = ref.watch(mediaSearchQueryProvider).trim().toLowerCase();

  return mediaAsync.whenData((items) {
    return items.where((item) {
      if (folder != 'all' && item.folder.toLowerCase() != folder) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesOriginal =
            item.originalName.toLowerCase().contains(query);
        if (!matchesName && !matchesOriginal) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

/// Operation state tracking uploads and mutations in the Media Library.
class MediaOperationState {
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? errorMessage;
  final MediaItem? lastUploadedItem;

  const MediaOperationState({
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.lastUploadedItem,
  });

  MediaOperationState copyWith({
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? errorMessage,
    bool clearError = false,
    MediaItem? lastUploadedItem,
  }) {
    return MediaOperationState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUploadedItem: lastUploadedItem ?? this.lastUploadedItem,
    );
  }
}

/// Controller managing file uploads, deletions, and operational state.
class MediaOperationController extends StateNotifier<MediaOperationState> {
  final Ref _ref;

  MediaOperationController(this._ref) : super(const MediaOperationState());

  /// Uploads an image picked from the computer into the target folder.
  /// Prevents concurrent duplicate uploads and enforces authorization and validations.
  Future<MediaItem?> uploadImage({
    String folder = 'general',
    SelectedMediaFile? preselectedFile,
  }) async {
    if (state.isUploading) {
      return null;
    }

    // Verify admin authorization
    final auth = _ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (!AdminConfig.isAuthorizedAdmin(user)) {
      state = state.copyWith(
        errorMessage:
            'Access denied: Only the verified administrator may upload media.',
      );
      return null;
    }

    SelectedMediaFile? file = preselectedFile;
    if (file == null) {
      final picker = _ref.read(mediaFilePickerProvider);
      try {
        file = await picker.pickImage();
      } catch (e) {
        state = state.copyWith(errorMessage: 'Failed to pick image: $e');
        return null;
      }
    }

    if (file == null) {
      return null; // User cancelled
    }

    // Validate file size, type, and binary payload magic bytes
    final validationError = MediaValidation.validateFile(
      name: file.name,
      sizeBytes: file.sizeBytes,
      bytes: file.bytes,
      contentType: file.contentType,
    );
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return null;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.05,
      clearError: true,
    );

    try {
      final repo = _ref.read(mediaRepositoryProvider);
      final uploadedItem = await repo.uploadMedia(
        file: file,
        folder: folder,
        adminUid: user!.uid,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );

      _ref.invalidate(mediaListProvider);
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        lastUploadedItem: uploadedItem,
      );
      return uploadedItem;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        errorMessage: 'Upload failed: $e',
      );
      return null;
    }
  }

  /// Permanently deletes a media asset after verifying it is not referenced.
  /// Fails closed if the reference check fails or if references are found.
  Future<bool> deleteMedia(
    MediaItem item, {
    bool skipReferenceCheck = false,
  }) async {
    final auth = _ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (!AdminConfig.isAuthorizedAdmin(user)) {
      state = state.copyWith(
        errorMessage:
            'Access denied: Only the verified administrator may delete media.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!skipReferenceCheck) {
        final refRepo = _ref.read(mediaReferenceRepositoryProvider);
        final checkResult = await refRepo.checkReferences(item);

        if (checkResult.hasError) {
          state = state.copyWith(
            isLoading: false,
            errorMessage:
                'Reference verification failed: ${checkResult.errorMessage}. Deletion blocked.',
          );
          return false;
        }

        if (checkResult.isReferenced) {
          state = state.copyWith(
            isLoading: false,
            errorMessage:
                'Cannot delete "${item.originalName}": Asset is in use by ${checkResult.referenceCount} content item(s).',
          );
          return false;
        }
      }

      final repo = _ref.read(mediaRepositoryProvider);
      await repo.deleteMedia(item);
      _ref.invalidate(mediaListProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete media: $e',
      );
      return false;
    }
  }

  /// Forces a fresh reload from Firebase Storage.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(mediaRepositoryProvider);
      await repo.getMediaItems(forceRefresh: true);
      _ref.invalidate(mediaListProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh media: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider exposing [MediaOperationController].
final mediaOperationControllerProvider =
    StateNotifierProvider<MediaOperationController, MediaOperationState>((ref) {
  return MediaOperationController(ref);
});
