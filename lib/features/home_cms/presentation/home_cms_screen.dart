import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/home_section_definition.dart';
import 'widgets/collection_section_view.dart';
import 'widgets/section_header_card.dart';
import 'widgets/singleton_section_editor.dart';

class HomeCmsScreen extends ConsumerStatefulWidget {
  const HomeCmsScreen({super.key});

  @override
  ConsumerState<HomeCmsScreen> createState() => _HomeCmsScreenState();
}

class _HomeCmsScreenState extends ConsumerState<HomeCmsScreen> {
  int _selectedSectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sections = HomeSectionDefinition.sections;
    final activeSection = sections[_selectedSectionIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sidebar: 13 Section Pills
                Container(
                  width: 280,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    border: Border(
                      right: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  child: _buildSectionSidebar(sections),
                ),

                // Right Pane: Active Section Editor
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionHeader(activeSection),
                            const SizedBox(height: 24),
                            _buildSectionBody(activeSection),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile / Tablet Stacked Layout
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMobileSectionSelector(sections),
                  const SizedBox(height: 20),
                  _buildSectionHeader(activeSection),
                  const SizedBox(height: 20),
                  _buildSectionBody(activeSection),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionSidebar(List<HomeSectionDefinition> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Website Sections',
                style: AppTypography.headingSmall().copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                '13 Home Page Content Modules',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final section = sections[index];
              final isSelected = index == _selectedSectionIndex;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Material(
                  color: isSelected
                      ? AppColors.primaryNavy
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() => _selectedSectionIndex = index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            section.icon,
                            size: 18,
                            color: isSelected
                                ? AppColors.primaryGold
                                : AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              section.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.surfaceWhite
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              section.isSingleton ? 'Section' : 'Collection',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.surfaceWhite
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSectionSelector(List<HomeSectionDefinition> sections) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedSectionIndex,
          isExpanded: true,
          items: [
            for (int i = 0; i < sections.length; i++)
              DropdownMenuItem(
                value: i,
                child: Row(
                  children: [
                    Icon(sections[i].icon,
                        size: 18, color: AppColors.primaryNavy),
                    const SizedBox(width: 10),
                    Text(
                      sections[i].title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      sections[i].isSingleton ? 'Section' : 'Collection',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedSectionIndex = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(HomeSectionDefinition section) {
    return SectionHeaderCard(section: section);
  }

  Widget _buildSectionBody(HomeSectionDefinition section) {
    if (section.isSingleton) {
      return SingletonSectionEditor(
        key: ValueKey(section.id),
        section: section,
      );
    } else {
      return CollectionSectionView(
        key: ValueKey(section.id),
        section: section,
      );
    }
  }
}
