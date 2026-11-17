/// Domain model representing an asset stored in Firebase Storage.
class MediaItem {
  final String id;
  final String name;
  final String originalName;
  final String fullPath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final String folder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? uploadedBy;

  const MediaItem({
    required this.id,
    required this.name,
    required this.originalName,
    required this.fullPath,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.folder,
    this.createdAt,
    this.updatedAt,
    this.uploadedBy,
  });

  /// Formatted human-readable file size (e.g. 2.4 MB, 450 KB).
  String get formattedSize {
    if (sizeBytes <= 0) return '0 B';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      final kb = (sizeBytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    }
    final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
    return '$mb MB';
  }

  /// Formatted date string for display.
  String get formattedDate {
    if (createdAt == null) return 'Unknown date';
    final dt = createdAt!;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// File extension without leading dot (lowercase).
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  /// Whether the file is an image format.
  bool get isImage {
    final ext = extension;
    return ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'png' ||
        ext == 'webp' ||
        contentType.startsWith('image/');
  }

  MediaItem copyWith({
    String? id,
    String? name,
    String? originalName,
    String? fullPath,
    String? downloadUrl,
    String? contentType,
    int? sizeBytes,
    String? folder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uploadedBy,
  }) {
    return MediaItem(
      id: id ?? this.id,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      fullPath: fullPath ?? this.fullPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      folder: folder ?? this.folder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'originalName': originalName,
      'fullPath': fullPath,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'folder': folder,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'uploadedBy': uploadedBy,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      originalName: map['originalName']?.toString() ?? map['name']?.toString() ?? '',
      fullPath: map['fullPath']?.toString() ?? '',
      downloadUrl: map['downloadUrl']?.toString() ?? '',
      contentType: map['contentType']?.toString() ?? 'image/jpeg',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      folder: map['folder']?.toString() ?? 'general',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
      uploadedBy: map['uploadedBy']?.toString(),
    );
  }
}

/// Validation rules and folder taxonomy for the Media Library.
class MediaValidation {
  /// Maximum file size allowed: 5 MB (5,242,880 bytes).
  static const int maxSizeBytes = 5 * 1024 * 1024;

  /// Allowed image file extensions.
  static const List<String> allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// Allowed MIME content types.
  static const List<String> allowedContentTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// Supported folder categories.
  static const List<String> folders = [
    'general',
    'homepage',
    'courses',
    'programs',
    'gallery',
  ];

  /// Detects the actual image format from its header magic bytes.
  /// Returns 'jpeg', 'png', 'webp', or `null` if unrecognized.
  static String? detectFormatFromBytes(List<int> bytes) {
    if (bytes.length < 12) return null;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpeg';
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'png';
    }

    // WebP: RIFF .... WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x45 && // E
        bytes[10] == 0x42 && // B
        bytes[11] == 0x50) { // P
      return 'webp';
    }

    return null;
  }

  /// Validates an image file before upload.
  /// Validates size, extension, MIME type, and binary magic bytes (payload signature).
  /// Returns `null` if valid, or a descriptive error message if invalid.
  static String? validateFile({
    required String name,
    required int sizeBytes,
    List<int>? bytes,
    String? contentType,
  }) {
    if (sizeBytes <= 0) {
      return 'The selected file is empty.';
    }

    if (sizeBytes > maxSizeBytes) {
      final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
      return 'Image size ($mb MB) exceeds the maximum allowed limit of 5 MB.';
    }

    final ext = _extractExtension(name);
    if (!allowedExtensions.contains(ext)) {
      return 'Unsupported file format (.$ext). Supported formats: JPG, JPEG, PNG, WebP.';
    }

    if (contentType != null && contentType.isNotEmpty) {
      final normalizedType = contentType.trim().toLowerCase();
      if (!allowedContentTypes.contains(normalizedType) &&
          !normalizedType.startsWith('image/')) {
        return 'Invalid MIME type ($contentType). Please select a valid image file.';
      }
    }

    // Binary magic byte validation when payload bytes are available
    if (bytes != null && bytes.isNotEmpty) {
      final detected = detectFormatFromBytes(bytes);
      if (detected == null) {
        return 'Corrupted or invalid image payload. File content does not match a recognized image format.';
      }

      final normalizedExt = ext == 'jpg' ? 'jpeg' : ext;
      if (detected != normalizedExt) {
        return 'File extension (.$ext) does not match the actual image content format ($detected).';
      }
    }

    return null;
  }

  /// Normalizes a folder name, defaulting unknown folders to `general`.
  static String normalizeFolder(String? folder) {
    if (folder == null) return 'general';
    final lower = folder.trim().toLowerCase();
    if (folders.contains(lower)) return lower;
    return 'general';
  }

  /// Infers standard MIME content type from filename.
  static String inferContentType(String name) {
    final ext = _extractExtension(name);
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  static String _extractExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }
}

