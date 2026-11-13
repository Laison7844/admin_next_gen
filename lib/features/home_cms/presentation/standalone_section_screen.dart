import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/home_section_definition.dart';
import 'widgets/collection_section_view.dart';
import 'widgets/section_header_card.dart';
import 'widgets/singleton_section_editor.dart';

/// Dedicated standalone screen for CMS sections accessed directly via sidebar routes
/// (e.g., /about, /courses, /programs, /gallery, /faqs, /settings).
///
/// Reuses the exact same [SingletonSectionEditor] or [CollectionSectionView]
/// components and business logic as the Home CMS multi-section editor.
class StandaloneSectionScreen extends StatelessWidget {
  final HomeSectionDefinition section;

  const StandaloneSectionScreen({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final horizontalPadding = isDesktop ? 32.0 : 16.0;
          final verticalPadding = isDesktop ? 28.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeaderCard(section: section),
                    const SizedBox(height: 24),
                    if (section.isSingleton)
                      SingletonSectionEditor(
                        key: ValueKey(section.id),
                        section: section,
                      )
                    else
                      CollectionSectionView(
                        key: ValueKey(section.id),
                        section: section,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

