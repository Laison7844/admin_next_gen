import 'package:admin_next_gen/core/constants/admin_config.dart';
import 'package:admin_next_gen/core/theme/app_typography.dart';
import 'package:admin_next_gen/features/auth/providers/auth_provider.dart';
import 'package:admin_next_gen/features/auth/services/auth_service.dart';
import 'package:admin_next_gen/features/media/data/media_reference_repository.dart';
import 'package:admin_next_gen/features/media/data/media_repository.dart';
import 'package:admin_next_gen/features/media/models/media_item.dart';
import 'package:admin_next_gen/features/media/models/media_reference.dart';
import 'package:admin_next_gen/features/media/presentation/widgets/media_delete_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;

  MockUser({required this.uid, this.email = 'admin@nextgen.edu'});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final User? _user;
  FakeAuthService([this._user]);

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
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class TestableMediaRepository implements MediaRepository {
  final Map<String, MediaItem> items = {};
  bool shouldFailDelete = false;

  TestableMediaRepository([List<MediaItem>? initial]) {
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
    return items.values.toList();
  }

  @override
  Future<MediaItem> uploadMedia({
    required dynamic file,
    required String folder,
    required String adminUid,
    void Function(double progress)? onProgress,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteMedia(MediaItem item) async {
    if (shouldFailDelete) {
      throw Exception('Simulated Storage deletion error: Network timed out');
    }
    items.remove(item.fullPath);
  }

  @override
  Future<MediaItem?> getMediaByPath(String fullPath) async => items[fullPath];
}

void main() {
  setUpAll(() {
    AppTypography.useSystemFont = true;
  });

  const testAsset = MediaItem(
    id: 'asset_1',
    name: 'target_image.webp',
    originalName: 'Target Image.webp',
    fullPath: 'media/general/target_image.webp',
    downloadUrl:
        'https://firebasestorage.googleapis.com/v0/b/next-gen-excellence.appspot.com/o/media%2Fgeneral%2Ftarget_image.webp?alt=media&token=tok-123',
    contentType: 'image/webp',
    sizeBytes: 1024 * 100,
    folder: 'general',
  );

  final adminUser = MockUser(uid: AdminConfig.authorizedAdminUid);

  group('Phase 4.12 — Media Reference Tracking & Safe Deletion Tests', () {
    late FakeMediaReferenceRepository refRepo;
    late TestableMediaRepository mediaRepo;

    setUp(() {
      refRepo = FakeMediaReferenceRepository();
      mediaRepo = TestableMediaRepository([testAsset]);
    });

    // 1. An image referenced by a course
    testWidgets('1. An image referenced by a course blocks deletion and shows In Use',
        (tester) async {
      refRepo.courses['course_1'] = {
        'title': 'Classes 1 - 7 All Subjects',
        'image': testAsset.downloadUrl,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.text('Permanent Deletion Blocked'), findsOneWidget);
      expect(find.textContaining('COURSES: Classes 1 - 7 All Subjects'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
    });

    // 2. An image referenced by a program
    testWidgets('2. An image referenced by a program blocks deletion', (tester) async {
      refRepo.programs['prog_spoken_english'] = {
        'title': 'Spoken English & Grammar',
        'data': {'image': testAsset.downloadUrl},
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.textContaining('PROGRAMS: Spoken English & Grammar'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 3. An image referenced by a gallery item
    testWidgets('3. An image referenced by a gallery item blocks deletion',
        (tester) async {
      refRepo.gallery['gal_campus'] = {
        'title': 'Main Campus Classroom',
        'image': testAsset.downloadUrl,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.textContaining('GALLERY: Main Campus Classroom'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 4. An image referenced by a testimonial
    testWidgets('4. An image referenced by a testimonial blocks deletion',
        (tester) async {
      refRepo.testimonials['testi_aarav'] = {
        'personName': 'Aarav Patel',
        'profileImage': testAsset.downloadUrl,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.textContaining('TESTIMONIALS: Aarav Patel'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 5. An image referenced by a homepage singleton section
    testWidgets('5. An image referenced by a homepage singleton section blocks deletion',
        (tester) async {
      refRepo.siteSections['hero'] = {
        'title': 'Hero Section',
        'heroImage': testAsset.downloadUrl,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.textContaining('SITE_SECTIONS: Hero Section'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 6. An image referenced by a CMS draft
    testWidgets('6. An image referenced by a CMS draft blocks deletion',
        (tester) async {
      refRepo.cmsDrafts['draft_courses_science'] = {
        'contentType': 'courses',
        'title': 'High School Physics & Chemistry',
        'data': {'image': testAsset.downloadUrl},
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.text('CMS DRAFT'), findsOneWidget);
      expect(find.textContaining('High School Physics & Chemistry'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 7. An image referenced through a nested map
    testWidgets('7. An image referenced through a deeply nested map is detected',
        (tester) async {
      refRepo.siteSections['custom_banner'] = {
        'title': 'Custom Promo',
        'config': {
          'theme': {
            'branding': {
              'heroBanner': testAsset.downloadUrl,
            }
          }
        }
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.textContaining('config.theme.branding.heroBanner'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 8. An image referenced inside a list
    testWidgets('8. An image referenced inside a list is detected', (tester) async {
      refRepo.siteSections['learning_modes'] = {
        'title': 'Learning Modes',
        'modes': [
          {'title': 'Offline Classes', 'image': 'https://other.com/offline.webp'},
          {'title': 'Live Online Classes', 'image': testAsset.downloadUrl},
        ]
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.textContaining('modes[1].image'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 9. An image with no references
    testWidgets('9. An image with no references allows deletion', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.text('No references found. This image is safe to delete.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    });

    // 10. Multiple references across different content types
    testWidgets('10. Multiple references across different content types are reported',
        (tester) async {
      refRepo.courses['course_1'] = {
        'title': 'Mathematics Grade 10',
        'image': testAsset.downloadUrl,
      };
      refRepo.testimonials['testi_1'] = {
        'personName': 'Sneha Rao',
        'profileImage': testAsset.downloadUrl,
      };
      refRepo.cmsDrafts['draft_hero'] = {
        'contentType': 'site_sections',
        'title': 'Hero Draft',
        'data': {'heroImage': testAsset.downloadUrl},
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('IN USE (3 references)'), findsOneWidget);
      expect(find.textContaining('COURSES: Mathematics Grade 10'), findsOneWidget);
      expect(find.textContaining('TESTIMONIALS: Sneha Rao'), findsOneWidget);
      expect(find.textContaining('SITE_SECTIONS: Hero Draft'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 11. Reference-check failure blocks deletion (Fail Closed)
    testWidgets('11. Reference-check failure blocks deletion (fail-closed)',
        (tester) async {
      refRepo.shouldFail = true;
      refRepo.failureMessage = 'Firestore connection timeout';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore connection timeout'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Retry Check'), findsOneWidget);
      expect(mediaRepo.items.containsKey(testAsset.fullPath), isTrue);
    });

    // 12. A reference added between initial check and deletion is detected by final recheck
    testWidgets(
        '12. Reference added between initial check and deletion is caught by recheck',
        (tester) async {
      // Initially unreferenced
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsOneWidget);

      // Concurrently add a reference before the user taps Delete
      refRepo.courses['concurrent_course'] = {
        'title': 'New Enrolled Batch Course',
        'image': testAsset.downloadUrl,
      };

      // User taps Delete Permanently
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Permanently'));
      await tester.pumpAndSettle();

      // Deletion was aborted by the pre-deletion recheck!
      expect(mediaRepo.items.containsKey(testAsset.fullPath), isTrue);
      expect(
          find.textContaining(
              'A reference was added during verification! Deletion has been blocked.'),
          findsOneWidget);
      expect(find.textContaining('IN USE (1 reference)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsNothing);
    });

    // 13. Successful deletion of an unreferenced asset
    testWidgets('13. Successful deletion of an unreferenced asset', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Delete Permanently'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Permanently'));
      await tester.pumpAndSettle();

      // Asset removed from repository
      expect(mediaRepo.items.containsKey(testAsset.fullPath), isFalse);
    });

    // 14. Failed Storage deletion produces a clear error and preserves UI state
    testWidgets('14. Failed Storage deletion produces clear error and preserves state',
        (tester) async {
      mediaRepo.shouldFailDelete = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(adminUser)),
            mediaRepositoryProvider.overrideWithValue(mediaRepo),
            mediaReferenceRepositoryProvider.overrideWithValue(refRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MediaDeleteDialog(item: testAsset),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Permanently'));
      await tester.pumpAndSettle();

      // Clear error is shown
      expect(find.textContaining('Simulated Storage deletion error'), findsOneWidget);
      // Item is not deleted
      expect(mediaRepo.items.containsKey(testAsset.fullPath), isTrue);
      // Dialog remains open
      expect(find.byType(MediaDeleteDialog), findsOneWidget);
    });
  });

  group('MediaReferenceScanner URL Normalization & Precision Unit Tests', () {
    test('Strict matching rejects loose substrings and prefix matches', () {
      expect(
        MediaReferenceScanner.isReferenceMatch(
          'https://firebasestorage.googleapis.com/v0/b/next-gen-excellence.appspot.com/o/media%2Fgeneral%2Ftarget_image.webp_thumb.png?alt=media',
          testAsset,
        ),
        isFalse,
      );

      expect(
        MediaReferenceScanner.isReferenceMatch(
          'https://firebasestorage.googleapis.com/v0/b/next-gen-excellence.appspot.com/o/media%2Fgeneral%2Fanother_target_image.webp?alt=media',
          testAsset,
        ),
        isFalse,
      );

      expect(
        MediaReferenceScanner.isReferenceMatch(
          'Check out target_image.webp for more details',
          testAsset,
        ),
        isFalse,
      );
    });

    test('Matches exact downloadUrl, fullPath, gs URI, and decoded storage path', () {
      // 1. Direct download URL
      expect(
        MediaReferenceScanner.isReferenceMatch(testAsset.downloadUrl, testAsset),
        isTrue,
      );

      // 2. Direct fullPath
      expect(
        MediaReferenceScanner.isReferenceMatch(testAsset.fullPath, testAsset),
        isTrue,
      );

      // 3. gs:// URL
      expect(
        MediaReferenceScanner.isReferenceMatch(
          'gs://next-gen-excellence.appspot.com/media/general/target_image.webp',
          testAsset,
        ),
        isTrue,
      );

      // 4. URL with different token
      expect(
        MediaReferenceScanner.isReferenceMatch(
          'https://firebasestorage.googleapis.com/v0/b/next-gen-excellence.appspot.com/o/media%2Fgeneral%2Ftarget_image.webp?alt=media&token=different-tok-999',
          testAsset,
        ),
        isTrue,
      );

      // 5. Google Cloud Storage URL
      expect(
        MediaReferenceScanner.isReferenceMatch(
          'https://storage.googleapis.com/next-gen-excellence.appspot.com/media/general/target_image.webp',
          testAsset,
        ),
        isTrue,
      );
    });
  });
}
