import 'dart:typed_data';
import 'package:admin_next_gen/core/constants/admin_config.dart';
import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/auth/providers/auth_provider.dart';
import 'package:admin_next_gen/features/auth/services/auth_service.dart';
import 'package:admin_next_gen/features/content/data/content_repository.dart';
import 'package:admin_next_gen/features/content/models/cms_content_item.dart';
import 'package:admin_next_gen/features/content/models/content_type.dart';
import 'package:admin_next_gen/features/content/providers/content_provider.dart';
import 'package:admin_next_gen/features/home_cms/models/home_section_definition.dart';
import 'package:admin_next_gen/features/home_cms/presentation/widgets/item_editor_dialog.dart';
import 'package:admin_next_gen/features/home_cms/presentation/widgets/singleton_section_editor.dart';
import 'package:admin_next_gen/features/media/data/media_repository.dart';
import 'package:admin_next_gen/features/media/models/media_item.dart';
import 'package:admin_next_gen/features/media/presentation/media_library_screen.dart';
import 'package:admin_next_gen/features/media/presentation/widgets/image_preview_dialog.dart';
import 'package:admin_next_gen/features/media/presentation/widgets/media_picker_dialog.dart';
import 'package:admin_next_gen/features/media/providers/media_provider.dart';
import 'package:admin_next_gen/features/media/services/media_file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTestUser implements User {
  @override
  final String uid;
  @override
  final String? email;

  MockTestUser({required this.uid, this.email = 'admin@nextgen.edu'});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTestAuthService implements AuthService {
  final User? _user;
  FakeTestAuthService([this._user]);

  @override
  Stream<User?> get authStateChanges => Stream.value(_user);

  @override
  User? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

class FakeMediaRepository implements MediaRepository {
  final Map<String, MediaItem> items = {};

  FakeMediaRepository([List<MediaItem>? initial]) {
    if (initial != null) {
      for (final i in initial) {
        items[i.fullPath] = i;
      }
    }
  }

  @override
  Future<List<MediaItem>> getMediaItems({
    String? folder,
    bool forceRefresh = false,
  }) async {
    final list = items.values.toList();
    list.sort((a, b) {
      final dtA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA);
    });

    if (folder == null || folder == 'all' || folder.isEmpty) {
      return list;
    }
    return list.where((i) => i.folder.toLowerCase() == folder.toLowerCase()).toList();
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
      contentType: file.contentType,
    );
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    onProgress?.call(0.5);
    onProgress?.call(1.0);

    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = 'media/$folder/$uniqueName';
    final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/next-gen-excellence.firebasestorage.app/o/$uniqueName';

    final newItem = MediaItem(
      id: uniqueName,
      name: uniqueName,
      originalName: file.name,
      fullPath: path,
      downloadUrl: downloadUrl,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
      folder: folder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      uploadedBy: adminUid,
    );

    items[path] = newItem;
    return newItem;
  }

  @override
  Future<void> deleteMedia(MediaItem item) async {
    items.remove(item.fullPath);
  }

  @override
  Future<MediaItem?> getMediaByPath(String fullPath) async => items[fullPath];
}

class FailingMediaRepository extends FakeMediaRepository {
  @override
  Future<MediaItem> uploadMedia({
    required SelectedMediaFile file,
    required String folder,
    required String adminUid,
    void Function(double progress)? onProgress,
  }) async {
    throw Exception('Simulated Firebase Storage network timeout');
  }
}

class FakeMediaFilePicker implements MediaFilePicker {
  SelectedMediaFile? nextFile;

  FakeMediaFilePicker({this.nextFile});

  @override
  Future<SelectedMediaFile?> pickImage() async => nextFile;
}

class FakeContentRepo implements ContentRepository {
  final Map<String, CmsContentItem> drafts = {};

  @override
  Future<List<CmsContentItem>> getDrafts({String? contentType}) async => drafts.values.toList();

  @override
  Future<CmsContentItem?> getDraft(String id) async => drafts[id];

  @override
  Future<Map<String, dynamic>?> getPublishedItem(String contentType, String id) async => null;

  @override
  Future<void> saveDraft(CmsContentItem item) async {
    drafts[item.id] = item;
  }

  @override
  Future<void> publish(String draftId, {DateTime? expectedUpdatedAt}) async {}

  @override
  Future<void> unpublish(String draftId) async {}

  @override
  Future<void> delete(String draftId) async {}

  @override
  Future<Set<String>> getPublishedDocIds(String contentType) async => const {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  group('MediaItem Model & Validation Tests', () {
    test('MediaItem round-trips via Map serialization', () {
      final now = DateTime(2026, 11, 16, 10, 0);
      final item = MediaItem(
        id: '123_hero.webp',
        name: '123_hero.webp',
        originalName: 'hero_student.webp',
        fullPath: 'media/homepage/123_hero.webp',
        downloadUrl: 'https://firebasestorage.googleapis.com/test',
        contentType: 'image/webp',
        sizeBytes: 1024 * 500, // 500 KB
        folder: 'homepage',
        createdAt: now,
        updatedAt: now,
        uploadedBy: 'p6awFfdX9jRKAScGwvSU9OMXjm72',
      );

      final map = item.toMap();
      final reconstructed = MediaItem.fromMap(map);

      expect(reconstructed.id, item.id);
      expect(reconstructed.originalName, 'hero_student.webp');
      expect(reconstructed.folder, 'homepage');
      expect(reconstructed.sizeBytes, 512000);
      expect(reconstructed.formattedSize, '500.0 KB');
      expect(reconstructed.extension, 'webp');
      expect(reconstructed.isImage, isTrue);
    });

    test('formattedSize formats bytes, KB, and MB correctly', () {
      const bItem = MediaItem(
        id: '1',
        name: 'a.png',
        originalName: 'a.png',
        fullPath: 'p',
        downloadUrl: 'u',
        contentType: 'image/png',
        sizeBytes: 800,
        folder: 'general',
      );
      expect(bItem.formattedSize, '800 B');

      const kbItem = MediaItem(
        id: '2',
        name: 'b.jpg',
        originalName: 'b.jpg',
        fullPath: 'p',
        downloadUrl: 'u',
        contentType: 'image/jpeg',
        sizeBytes: 153600, // 150 KB
        folder: 'general',
      );
      expect(kbItem.formattedSize, '150.0 KB');

      const mbItem = MediaItem(
        id: '3',
        name: 'c.webp',
        originalName: 'c.webp',
        fullPath: 'p',
        downloadUrl: 'u',
        contentType: 'image/webp',
        sizeBytes: 2621440, // 2.5 MB
        folder: 'general',
      );
      expect(mbItem.formattedSize, '2.50 MB');
    });

    test('MediaValidation validates file size limit (5 MB)', () {
      // 4 MB valid
      expect(
        MediaValidation.validateFile(
          name: 'photo.jpg',
          sizeBytes: 4 * 1024 * 1024,
          contentType: 'image/jpeg',
        ),
        isNull,
      );

      // Exactly 5 MB valid
      expect(
        MediaValidation.validateFile(
          name: 'photo.png',
          sizeBytes: 5 * 1024 * 1024,
          contentType: 'image/png',
        ),
        isNull,
      );

      // 5 MB + 1 byte invalid
      final err = MediaValidation.validateFile(
        name: 'large.webp',
        sizeBytes: 5 * 1024 * 1024 + 1,
        contentType: 'image/webp',
      );
      expect(err, contains('exceeds the maximum allowed limit of 5 MB'));
    });

    test('MediaValidation enforces allowed file extensions', () {
      expect(
        MediaValidation.validateFile(
          name: 'test.jpg',
          sizeBytes: 1000,
          contentType: 'image/jpeg',
        ),
        isNull,
      );
      expect(
        MediaValidation.validateFile(
          name: 'test.jpeg',
          sizeBytes: 1000,
          contentType: 'image/jpeg',
        ),
        isNull,
      );
      expect(
        MediaValidation.validateFile(
          name: 'test.png',
          sizeBytes: 1000,
          contentType: 'image/png',
        ),
        isNull,
      );
      expect(
        MediaValidation.validateFile(
          name: 'test.webp',
          sizeBytes: 1000,
          contentType: 'image/webp',
        ),
        isNull,
      );

      // Invalid extensions
      final pdfErr = MediaValidation.validateFile(
        name: 'document.pdf',
        sizeBytes: 1000,
      );
      expect(pdfErr, contains('Unsupported file format (.pdf)'));

      final exeErr = MediaValidation.validateFile(
        name: 'program.exe',
        sizeBytes: 1000,
      );
      expect(exeErr, contains('Unsupported file format (.exe)'));
    });

    test('MediaValidation validates empty files and normalizes folders', () {
      final emptyErr = MediaValidation.validateFile(
        name: 'empty.png',
        sizeBytes: 0,
      );
      expect(emptyErr, contains('The selected file is empty'));

      expect(MediaValidation.normalizeFolder(null), 'general');
      expect(MediaValidation.normalizeFolder('unknown'), 'general');
      expect(MediaValidation.normalizeFolder('homepage'), 'homepage');
      expect(MediaValidation.normalizeFolder('COURSES'), 'courses');
      expect(MediaValidation.normalizeFolder('gallery'), 'gallery');
    });

    test('MediaValidation validates actual payload bytes and rejects mismatched extensions', () {
      final validJpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01];
      final validPng = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D];
      final validWebp = [0x52, 0x49, 0x46, 0x46, 0x20, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50];
      final corruptBytes = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C];

      // Format detection from bytes
      expect(MediaValidation.detectFormatFromBytes(validJpeg), 'jpeg');
      expect(MediaValidation.detectFormatFromBytes(validPng), 'png');
      expect(MediaValidation.detectFormatFromBytes(validWebp), 'webp');
      expect(MediaValidation.detectFormatFromBytes(corruptBytes), isNull);

      // Valid payloads match extension
      expect(
        MediaValidation.validateFile(
          name: 'photo.jpg',
          sizeBytes: validJpeg.length,
          bytes: validJpeg,
        ),
        isNull,
      );
      expect(
        MediaValidation.validateFile(
          name: 'graphic.png',
          sizeBytes: validPng.length,
          bytes: validPng,
        ),
        isNull,
      );
      expect(
        MediaValidation.validateFile(
          name: 'banner.webp',
          sizeBytes: validWebp.length,
          bytes: validWebp,
        ),
        isNull,
      );

      // Rejects corrupt/non-image bytes even if extension says .jpg
      final corruptErr = MediaValidation.validateFile(
        name: 'script.jpg',
        sizeBytes: corruptBytes.length,
        bytes: corruptBytes,
      );
      expect(corruptErr, contains('Corrupted or invalid image payload'));

      // Rejects extension/MIME mismatch (e.g. genuine PNG named .jpg)
      final mismatchErr = MediaValidation.validateFile(
        name: 'sneaky.jpg',
        sizeBytes: validPng.length,
        bytes: validPng,
      );
      expect(mismatchErr, contains('File extension (.jpg) does not match the actual image content format (png)'));
    });
  });

  group('MediaRepository & Operation Controller Tests', () {
    test('uploadMedia persists item and enforces folder scope', () async {
      final repo = FakeMediaRepository();
      final validJpegBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01
      ]);

      final item = await repo.uploadMedia(
        file: SelectedMediaFile(
          name: 'classroom.jpg',
          bytes: validJpegBytes,
          sizeBytes: validJpegBytes.length,
          contentType: 'image/jpeg',
        ),
        folder: 'courses',
        adminUid: AdminConfig.authorizedAdminUid,
      );

      expect(item.originalName, 'classroom.jpg');
      expect(item.folder, 'courses');
      expect(item.uploadedBy, AdminConfig.authorizedAdminUid);
      expect(repo.items.length, 1);

      // Filtering by folder
      final coursesOnly = await repo.getMediaItems(folder: 'courses');
      expect(coursesOnly.length, 1);

      final homepageOnly = await repo.getMediaItems(folder: 'homepage');
      expect(homepageOnly.length, 0);
    });

    test('deleteMedia removes item from repository', () async {
      final item = const MediaItem(
        id: 'img1',
        name: 'img1.png',
        originalName: 'img1.png',
        fullPath: 'media/general/img1.png',
        downloadUrl: 'url',
        contentType: 'image/png',
        sizeBytes: 100,
        folder: 'general',
      );
      final repo = FakeMediaRepository([item]);
      expect(repo.items.length, 1);

      await repo.deleteMedia(item);
      expect(repo.items.length, 0);
    });

    test('Controller uploadImage succeeds for verified administrator', () async {
      final repo = FakeMediaRepository();
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);
      final authService = FakeTestAuthService(adminUser);
      final validPngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D
      ]);
      final picker = FakeMediaFilePicker(
        nextFile: SelectedMediaFile(
          name: 'badge.png',
          bytes: validPngBytes,
          sizeBytes: validPngBytes.length,
          contentType: 'image/png',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
          mediaRepositoryProvider.overrideWithValue(repo),
          mediaFilePickerProvider.overrideWithValue(picker),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(mediaOperationControllerProvider.notifier);
      final result = await controller.uploadImage(folder: 'gallery');

      expect(result, isNotNull);
      expect(result?.originalName, 'badge.png');
      expect(result?.folder, 'gallery');
      expect(container.read(mediaOperationControllerProvider).errorMessage, isNull);
    });

    test('Controller uploadImage blocks unauthorized non-admin user', () async {
      final repo = FakeMediaRepository();
      final nonAdminUser = MockTestUser(uid: 'unauthorized_uid_999');
      final authService = FakeTestAuthService(nonAdminUser);
      final validPngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D
      ]);
      final picker = FakeMediaFilePicker(
        nextFile: SelectedMediaFile(
          name: 'badge.png',
          bytes: validPngBytes,
          sizeBytes: validPngBytes.length,
          contentType: 'image/png',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
          mediaRepositoryProvider.overrideWithValue(repo),
          mediaFilePickerProvider.overrideWithValue(picker),
        ],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(mediaOperationControllerProvider.notifier);
      final result = await controller.uploadImage(folder: 'gallery');

      expect(result, isNull);
      expect(
        container.read(mediaOperationControllerProvider).errorMessage,
        contains('Only the verified administrator may upload media'),
      );
    });

    test('Controller uploadImage resets state and records error on upload failure', () async {
      final repo = FailingMediaRepository();
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);
      final authService = FakeTestAuthService(adminUser);
      final validPng = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D
      ]);
      final picker = FakeMediaFilePicker(
        nextFile: SelectedMediaFile(
          name: 'fail.png',
          bytes: validPng,
          sizeBytes: validPng.length,
          contentType: 'image/png',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
          mediaRepositoryProvider.overrideWithValue(repo),
          mediaFilePickerProvider.overrideWithValue(picker),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(mediaOperationControllerProvider.notifier);
      final result = await controller.uploadImage(folder: 'homepage');

      expect(result, isNull);
      final state = container.read(mediaOperationControllerProvider);
      expect(state.isUploading, isFalse);
      expect(state.uploadProgress, 0.0);
      expect(state.errorMessage, contains('Simulated Firebase Storage network timeout'));
    });
  });

  group('MediaLibraryScreen Widget Tests', () {
    testWidgets('Renders empty state with upload CTA when no media exists',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeMediaRepository();
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeTestAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MediaLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Media Library'), findsOneWidget);
      expect(find.text('Asset Library'), findsOneWidget);
      expect(find.text('Total Assets'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
      expect(find.text('No images uploaded yet'), findsOneWidget);
      expect(find.text('Upload Your First Image'), findsOneWidget);
    });

    testWidgets('Displays assets in Grid view and allows folder filtering',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeMediaRepository([
        const MediaItem(
          id: 'item1',
          name: 'hero_img.webp',
          originalName: 'Hero Student.webp',
          fullPath: 'media/homepage/hero_img.webp',
          downloadUrl: 'https://example.com/hero.webp',
          contentType: 'image/webp',
          sizeBytes: 1024 * 200,
          folder: 'homepage',
        ),
        const MediaItem(
          id: 'item2',
          name: 'lab.jpg',
          originalName: 'Computer Lab.jpg',
          fullPath: 'media/courses/lab.jpg',
          downloadUrl: 'https://example.com/lab.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 1024 * 350,
          folder: 'courses',
        ),
      ]);
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeTestAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MediaLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hero Student.webp'), findsOneWidget);
      expect(find.text('Computer Lab.jpg'), findsOneWidget);
      expect(find.text('HOMEPAGE'), findsNWidgets(2)); // ChoiceChip and card tag
      expect(find.text('COURSES'), findsWidgets);

      // Filter by HOMEPAGE folder
      await tester.tap(find.widgetWithText(ChoiceChip, 'HOMEPAGE'));
      await tester.pumpAndSettle();

      expect(find.text('Hero Student.webp'), findsOneWidget);
      expect(find.text('Computer Lab.jpg'), findsNothing);

      // Filter by ALL
      await tester.tap(find.widgetWithText(ChoiceChip, 'ALL'));
      await tester.pumpAndSettle();

      expect(find.text('Hero Student.webp'), findsOneWidget);
      expect(find.text('Computer Lab.jpg'), findsOneWidget);
    });

    testWidgets('Search filters media assets by filename', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeMediaRepository([
        const MediaItem(
          id: 'item1',
          name: 'banner_student.webp',
          originalName: 'Annual Day Banner.webp',
          fullPath: 'media/general/banner_student.webp',
          downloadUrl: 'https://example.com/banner.webp',
          contentType: 'image/webp',
          sizeBytes: 1024 * 200,
          folder: 'general',
        ),
        const MediaItem(
          id: 'item2',
          name: 'math_tuition.jpg',
          originalName: 'Abacus Tuition.jpg',
          fullPath: 'media/courses/math_tuition.jpg',
          downloadUrl: 'https://example.com/abacus.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 1024 * 350,
          folder: 'courses',
        ),
      ]);
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeTestAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MediaLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search for "Abacus"
      await tester.enterText(find.byType(TextField).first, 'Abacus');
      await tester.pumpAndSettle();

      expect(find.text('Abacus Tuition.jpg'), findsOneWidget);
      expect(find.text('Annual Day Banner.webp'), findsNothing);
    });

    testWidgets('Delete button shows confirmation dialog and removes asset',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeMediaRepository([
        const MediaItem(
          id: 'item_del',
          name: 'to_delete.png',
          originalName: 'Old Certificate.png',
          fullPath: 'media/general/to_delete.png',
          downloadUrl: 'https://example.com/del.png',
          contentType: 'image/png',
          sizeBytes: 1024 * 50,
          folder: 'general',
        ),
      ]);
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeTestAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MediaLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Old Certificate.png'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byTooltip('Delete Image'));
      await tester.pumpAndSettle();

      expect(find.text('Permanently Delete Image?'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Permanently'));
      await tester.pumpAndSettle();

      expect(repo.items.isEmpty, isTrue);
      expect(find.text('Old Certificate.png'), findsNothing);
    });

    testWidgets('Canceling delete confirmation dialog preserves asset safely',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeMediaRepository([
        const MediaItem(
          id: 'safe_img',
          name: 'safe_banner.webp',
          originalName: 'Active Homepage Banner.webp',
          fullPath: 'media/homepage/safe_banner.webp',
          downloadUrl: 'https://example.com/safe.webp',
          contentType: 'image/webp',
          sizeBytes: 1024 * 60,
          folder: 'homepage',
        ),
      ]);
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeTestAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MediaLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Homepage Banner.webp'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byTooltip('Delete Image'));
      await tester.pumpAndSettle();

      expect(find.text('Permanently Delete Image?'), findsOneWidget);

      // Cancel deletion
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Asset remains intact
      expect(repo.items.containsKey('media/homepage/safe_banner.webp'), isTrue);
      expect(find.text('Active Homepage Banner.webp'), findsOneWidget);
    });

    testWidgets('Inspect button opens ImagePreviewDialog with details and copy action',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeMediaRepository([
        const MediaItem(
          id: 'item_prev',
          name: 'preview_asset.png',
          originalName: 'Campus Photo.png',
          fullPath: 'media/gallery/preview_asset.png',
          downloadUrl: 'https://firebasestorage.googleapis.com/campus.png',
          contentType: 'image/png',
          sizeBytes: 1024 * 120,
          folder: 'gallery',
        ),
      ]);
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeTestAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MediaLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap inspect
      await tester.tap(find.byTooltip('Inspect Image'));
      await tester.pumpAndSettle();

      expect(find.byType(ImagePreviewDialog), findsOneWidget);
      expect(find.text('Asset Information'), findsOneWidget);
      expect(find.text('Original Filename'), findsOneWidget);
      expect(find.text('Campus Photo.png'), findsWidgets);
      expect(find.text('media/gallery/preview_asset.png'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Copy URL'), findsOneWidget);

      // Close dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
      await tester.pumpAndSettle();

      expect(find.byType(ImagePreviewDialog), findsNothing);
    });
  });

  group('MediaPickerDialog & Image Reuse Integration Tests', () {
    testWidgets('MediaPickerDialog displays items and selects image',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeMediaRepository([
        const MediaItem(
          id: 'picked_img',
          name: 'picked.webp',
          originalName: 'Tuition Poster.webp',
          fullPath: 'media/courses/picked.webp',
          downloadUrl: 'https://firebasestorage.googleapis.com/poster.webp',
          contentType: 'image/webp',
          sizeBytes: 1024 * 80,
          folder: 'courses',
        ),
      ]);
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);

      MediaItem? chosenItem;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeTestAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    chosenItem = await MediaPickerDialog.show(
                      context,
                      preferredFolder: 'courses',
                    );
                  },
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open picker
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.byType(MediaPickerDialog), findsOneWidget);
      expect(find.text('Tuition Poster.webp'), findsOneWidget);

      // Tap the image card to select
      await tester.tap(find.text('Tuition Poster.webp'));
      await tester.pumpAndSettle();

      expect(find.text('Selected: Tuition Poster.webp'), findsOneWidget);

      // Click "Select Image"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Select Image'));
      await tester.pumpAndSettle();

      expect(find.byType(MediaPickerDialog), findsNothing);
      expect(chosenItem, isNotNull);
      expect(chosenItem?.originalName, 'Tuition Poster.webp');
      expect(chosenItem?.downloadUrl, 'https://firebasestorage.googleapis.com/poster.webp');
    });

    testWidgets('ItemEditorDialog provides Media Library picker button',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ItemEditorDialog(
                contentType: ContentType.gallery,
                onSave: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Image URL or Asset Path *'), findsOneWidget);
      expect(find.text('Media Library'), findsOneWidget);
    });

    testWidgets('SingletonSectionEditor provides Media Library picker button for heroImage',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final section = HomeSectionDefinition.getById('home_hero');
      final adminUser = MockTestUser(uid: AdminConfig.authorizedAdminUid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeTestAuthService(adminUser)),
            contentRepositoryProvider.overrideWithValue(FakeContentRepo()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SingletonSectionEditor(section: section),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hero Illustration / Image URL'), findsOneWidget);
      expect(find.text('Media Library'), findsOneWidget);
    });
  });
}
