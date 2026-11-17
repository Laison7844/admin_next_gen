import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';

/// Represents a raw file selected from the computer for upload.
class SelectedMediaFile {
  final String name;
  final Uint8List bytes;
  final int sizeBytes;
  final String contentType;

  const SelectedMediaFile({
    required this.name,
    required this.bytes,
    required this.sizeBytes,
    required this.contentType,
  });
}

/// Abstract contract for picking media files in Flutter Web.
abstract class MediaFilePicker {
  Future<SelectedMediaFile?> pickImage();
}

/// Default implementation using the cross-platform `file_picker` package.
class PlatformMediaFilePicker implements MediaFilePicker {
  const PlatformMediaFilePicker();

  @override
  Future<SelectedMediaFile?> pickImage() async {
    final platformFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: MediaValidation.allowedExtensions,
    );

    if (platformFile == null) {
      return null;
    }

    final bytes = await platformFile.readAsBytes();
    final size = await platformFile.length() ?? bytes.length;

    return SelectedMediaFile(
      name: platformFile.name,
      bytes: bytes,
      sizeBytes: size,
      contentType: MediaValidation.inferContentType(platformFile.name),
    );
  }
}

/// Riverpod provider for [MediaFilePicker], overridable in tests.
final mediaFilePickerProvider = Provider<MediaFilePicker>((ref) {
  return const PlatformMediaFilePicker();
});
