import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/home_section_definition.dart';
import 'widgets/section_header_card.dart';
import 'widgets/singleton_section_editor.dart';

class HomeCmsScreen extends ConsumerStatefulWidget {
  const HomeCmsScreen({super.key});

  @override
  ConsumerState<HomeCmsScreen> createState() => _HomeCmsScreenState();
}

class _HomeCmsScreenState extends ConsumerState<HomeCmsScreen> {
  static const List<String> _homepageSectionIds = [
    'home_hero',
    'feature_highlights',
    'why_nextgen',
    'learning_modes',
    'pledge',
    'assessments',
    'banner_cta',
  ];

  late final List<HomeSectionDefinition> _homepageSections;
  int _selectedSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _homepageSections = _homepageSectionIds
        .map((id) => HomeSectionDefinition.getById(id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeSection = _homepageSections[_selectedSectionIndex];

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
                    // Page Title & Overview Header
                    _buildPageHeader(isDesktop),
                    const SizedBox(height: 20),

                    // Homepage Sections Selector (7 Focused Homepage Modules)
                    _buildSectionSelector(isDesktop),
                    const SizedBox(height: 24),

                    // Active Section Header Details
                    SectionHeaderCard(section: activeSection),
                    const SizedBox(height: 24),

                    // Focused Singleton Content Editor
                    SingletonSectionEditor(
                      key: ValueKey(activeSection.id),
                      section: activeSection,
                    ),
                    const SizedBox(height: 32),

                    // Cross-Module Sidebar Discovery Callout
                    _buildSidebarDiscoveryNotice(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 22 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060B1B3D),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_outlined,
              color: AppColors.primaryGold,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Home',
                      style: AppTypography.headingMedium(
                        color: AppColors.primaryNavy,
                      ).copyWith(fontSize: isDesktop ? 22 : 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.softGoldBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Homepage Content',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage the content displayed on your website homepage.',
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Homepage Sections',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              Text(
                '(${_homepageSections.length} sections)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _homepageSections.length; i++) ...[
                  _buildSectionTab(i, _homepageSections[i]),
                  if (i < _homepageSections.length - 1)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab(int index, HomeSectionDefinition section) {
    final isSelected = index == _selectedSectionIndex;

    return Material(
      color: isSelected ? AppColors.primaryNavy : AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() => _selectedSectionIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                section.icon,
                size: 16,
                color: isSelected
                    ? AppColors.primaryGold
                    : AppColors.primaryNavy,
              ),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.surfaceWhite
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarDiscoveryNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softBlueBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.infoBlue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Looking to manage Courses, Special Programs, Gallery, Testimonials, or FAQs? '
              'Access them anytime directly from the main navigation sidebar.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
