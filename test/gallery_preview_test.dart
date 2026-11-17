import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_next_gen/features/home_cms/models/home_section_definition.dart';
import 'package:admin_next_gen/features/home_cms/presentation/widgets/section_preview_dialog.dart';

void main() {
  group('Phase 4.22.2 - CMS Gallery Preview & Contract Tests', () {
    final gallerySection = HomeSectionDefinition.sections.firstWhere(
      (s) => s.id == 'gallery',
    );

    testWidgets('Gallery preview renders title, category badge, and image without raw URL text', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const sampleUrl = 'https://firebasestorage.googleapis.com/v0/b/next-gen-excellence.firebasestorage.app/o/media%2Fhomepage%2F1794899889937_sample.png';
      final galleryData = {
        'id': 'robotics',
        'title': 'New courses',
        'category': 'Campus Setup',
        'description': 'Advanced robotics course lab.',
        'image': sampleUrl,
        'order': 1,
        'isVisible': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionPreviewDialog(
              section: gallerySection,
              data: galleryData,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Preview: Gallery'), findsOneWidget);
      expect(find.text('New courses'), findsOneWidget);
      expect(find.text('Campus Setup'), findsOneWidget);
      expect(find.text('Advanced robotics course lab.'), findsOneWidget);

      // Verify the raw URL is NOT rendered as visible text in the dialog
      expect(find.text(sampleUrl), findsNothing);
    });

    testWidgets('Invalid image URL displays neutral error state and never shows raw URL text', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const brokenUrl = 'https://invalid-broken-domain.example.com/notfound.png';
      final brokenData = {
        'id': 'robotics',
        'title': 'New courses',
        'category': 'Lab',
        'description': '',
        'image': brokenUrl,
        'order': 1,
        'isVisible': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionPreviewDialog(
              section: gallerySection,
              data: brokenData,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New courses'), findsOneWidget);
      // Neutral error message is shown
      expect(find.text('Unable to load Gallery Photo'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

      // Verify the broken URL string is NOT displayed
      expect(find.text(brokenUrl), findsNothing);
    });

    testWidgets('Empty or unconfigured image URL displays neutral placeholder', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final emptyData = {
        'id': 'robotics',
        'title': 'New courses',
        'category': '',
        'description': '',
        'image': '',
        'order': 1,
        'isVisible': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionPreviewDialog(
              section: gallerySection,
              data: emptyData,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New courses'), findsOneWidget);
      expect(find.text('No Gallery Photo URL configured'), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });
}
