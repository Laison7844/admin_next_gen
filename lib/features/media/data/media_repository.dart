import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../services/media_file_picker.dart';

/// Abstract repository defining media asset management operations.
abstract class MediaRepository {
  /// Fetches media items, optionally filtered by folder category.
  Future<List<MediaItem>> getMediaItems({
    String? folder,
    bool forceRefresh = false,
  });

  /// Uploads a selected file to the specified Storage folder.
  Future<MediaItem> uploadMedia({
    required SelectedMediaFile file,
    required String folder,
    required String adminUid,
    void Function(double progress)? onProgress,
  });

  /// Permanently removes a media asset from Firebase Storage.
  Future<void> deleteMedia(MediaItem item);

  /// Retrieves metadata for a specific storage path.
  Future<MediaItem?> getMediaByPath(String fullPath);
}

/// Firebase Storage implementation of [MediaRepository].
class FirebaseMediaRepository implements MediaRepository {
  final FirebaseStorage _storage;
  List<MediaItem>? _cachedItems;

  FirebaseMediaRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<List<MediaItem>> getMediaItems({
    String? folder,
    bool forceRefresh = false,
  }) async {
    if (_cachedItems == null || forceRefresh) {
      final List<MediaItem> loaded = [];

      for (final folderName in MediaValidation.folders) {
        try {
          final ListResult listResult =
              await _storage.ref('media/$folderName').listAll();

          for (final itemRef in listResult.items) {
            try {
              final FullMetadata meta = await itemRef.getMetadata();
              final String downloadUrl = await itemRef.getDownloadURL();

              final originalName =
                  meta.customMetadata?['originalName'] ?? itemRef.name;
              final uploadedBy = meta.customMetadata?['uploadedBy'];
              final assignedFolder =
                  meta.customMetadata?['folder'] ?? folderName;

              loaded.add(
                MediaItem(
                  id: itemRef.name,
                  name: itemRef.name,
                  originalName: originalName,
                  fullPath: itemRef.fullPath,
                  downloadUrl: downloadUrl,
                  contentType: meta.contentType ?? 'image/jpeg',
                  sizeBytes: meta.size ?? 0,
                  folder: assignedFolder,
                  createdAt: meta.timeCreated,
                  updatedAt: meta.updated,
                  uploadedBy: uploadedBy,
                ),
              );
            } catch (_) {
              // Gracefully continue if an individual item cannot be resolved
            }
          }
        } catch (_) {
          // Folder may not exist yet in a fresh storage bucket
        }
      }

      // Sort newest first
      loaded.sort((a, b) {
        final dtA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dtB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dtB.compareTo(dtA);
      });

      _cachedItems = loaded;
    }

    final all = _cachedItems ?? [];
    if (folder == null || folder == 'all' || folder.isEmpty) {
      return List.unmodifiable(all);
    }

    final normalized = MediaValidation.normalizeFolder(folder);
    return List.unmodifiable(
      all.where((item) => item.folder.toLowerCase() == normalized).toList(),
    );
  }

  @override
  Future<MediaItem> uploadMedia({
    required SelectedMediaFile file,
    required String folder,
    required String adminUid,
    void Function(double progress)? onProgress,
  }) async {
    final validationError = MediaValidation.validateFile(
      name: file.name,
      sizeBytes: file.sizeBytes,
      bytes: file.bytes,
      contentType: file.contentType,
    );
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final targetFolder = MediaValidation.normalizeFolder(folder);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitized = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final uniqueName = '${timestamp}_$sanitized';
    final storagePath = 'media/$targetFolder/$uniqueName';

    final Reference ref = _storage.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: file.contentType,
      customMetadata: {
        'originalName': file.name,
        'uploadedBy': adminUid,
        'folder': targetFolder,
      },
    );

    final UploadTask task = ref.putData(file.bytes, metadata);

    if (onProgress != null) {
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress.clamp(0.0, 1.0));
        }
      });
    }

    await task;
    final String downloadUrl = await ref.getDownloadURL();

    final newItem = MediaItem(
      id: uniqueName,
      name: uniqueName,
      originalName: file.name,
      fullPath: storagePath,
      downloadUrl: downloadUrl,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
      folder: targetFolder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      uploadedBy: adminUid,
    );

    if (_cachedItems != null) {
      _cachedItems!.removeWhere((i) => i.fullPath == newItem.fullPath);
      _cachedItems!.insert(0, newItem);
    }

    return newItem;
  }

  @override
  Future<void> deleteMedia(MediaItem item) async {
    final Reference ref = _storage.ref(item.fullPath);
    await ref.delete();

    if (_cachedItems != null) {
      _cachedItems!.removeWhere((i) => i.fullPath == item.fullPath);
    }
  }

  @override
  Future<MediaItem?> getMediaByPath(String fullPath) async {
    final all = await getMediaItems();
    try {
      return all.firstWhere((item) => item.fullPath == fullPath);
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod provider for [MediaRepository], overridable in tests.
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return FirebaseMediaRepository();
});

