import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/home_section_definition.dart';

class SectionPreviewDialog extends StatelessWidget {
  final HomeSectionDefinition section;
  final Map<String, dynamic> data;

  const SectionPreviewDialog({
    super.key,
    required this.section,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.primaryGold,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview: ${section.title}',
                          style: AppTypography.headingSmall(
                            color: AppColors.surfaceWhite,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Draft Rendering (CMS Preview — Approximation of public styling)',
                          style: AppTypography.bodySmall(
                            color: const Color(0xFFC0CCE2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.surfaceWhite),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content preview container
            Expanded(
              child: Container(
                color: AppColors.backgroundLight,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: _buildSectionPreview(),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(
                  top: BorderSide(color: AppColors.borderLight, width: 1),
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Preview displays current working draft payload.',
                          style: AppTypography.bodySmall(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close Preview'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPreview() {
    switch (section.id) {
      case 'home_hero':
        return _buildHeroPreview();
      case 'feature_highlights':
        return _buildFeatureHighlightsPreview();
      case 'about_us':
        return _buildAboutPreview();
      case 'courses':
        return _buildCoursesPreview();
      case 'programs':
        return _buildProgramsPreview();
      case 'why_nextgen':
        return _buildWhyNextGenPreview();
      case 'learning_modes':
        return _buildLearningModesPreview();
      case 'pledge':
        return _buildPledgePreview();
      case 'assessments':
        return _buildAssessmentsPreview();
      case 'banner_cta':
        return _buildBannerCtaPreview();
      case 'gallery':
        return _buildGalleryPreview();
      case 'faqs':
        return _buildFaqsPreview();
      case 'contact_footer':
        return _buildContactPreview();
      default:
        return _buildGenericCardPreview();
    }
  }

  // 1. HERO PREVIEW
  Widget _buildHeroPreview() {
    final subTagline =
        data['subTagline']?.toString() ?? data['subtitle']?.toString() ?? '';
    final mainTitle = data['mainTitle']?.toString() ?? '';
    final highlightedTitle = data['highlightedTitle']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final primaryBtn = data['primaryButtonLabel']?.toString() ?? 'Explore Programs';
    final secondaryBtn = data['secondaryButtonLabel']?.toString() ?? 'Contact Us';
    final chips = (data['featureChips'] as List?) ?? [];
    final heroImage = data['heroImage']?.toString();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subTagline.isNotEmpty) ...[
            Text(
              subTagline,
              style: AppTypography.titleMedium(color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 12),
          ],
          RichText(
            text: TextSpan(
              style: AppTypography.headingLarge(color: AppColors.primaryNavy),
              children: [
                TextSpan(text: '$mainTitle '),
                TextSpan(
                  text: highlightedTitle,
                  style: const TextStyle(color: AppColors.primaryGold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(description, style: AppTypography.bodyMedium()),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: AppColors.surfaceWhite,
                ),
                child: Text(primaryBtn),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  side: const BorderSide(color: AppColors.primaryNavy),
                ),
                child: Text(secondaryBtn),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildImagePreview(heroImage, label: 'Hero Illustration'),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: chips.map((c) {
                if (c is Map) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.softBlueBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c['title'] ?? ''} • ${c['subtitle'] ?? ''}',
                      style: AppTypography.bodySmall(color: AppColors.primaryNavy),
                    ),
                  );
                }
                return Chip(label: Text(c.toString()));
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // 2. FEATURE HIGHLIGHTS PREVIEW
  Widget _buildFeatureHighlightsPreview() {
    final features = List<Map<String, dynamic>>.from(
      (data['features'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ??
          (data['featureHighlights'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map)) ??
          [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Core Feature Highlights', style: AppTypography.headingSmall()),
        const SizedBox(height: 6),
        Text('Six foundational learning pillars below the Hero banner.',
            style: AppTypography.bodySmall(color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        for (final feat in features) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.softBlueBg,
                  child: Icon(
                    _getIconData(feat['icon']?.toString()),
                    color: AppColors.primaryNavy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            feat['title']?.toString() ?? 'Highlight',
                            style: AppTypography.titleMedium(),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: feat['isVisible'] != false
                                  ? AppColors.successGreen.withValues(alpha: 0.12)
                                  : AppColors.borderLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              feat['isVisible'] != false ? 'Visible' : 'Hidden',
                              style: TextStyle(
                                fontSize: 11,
                                color: feat['isVisible'] != false
                                    ? AppColors.successGreen
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feat['description']?.toString() ?? '',
                        style: AppTypography.bodySmall(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 3. ABOUT US PREVIEW
  Widget _buildAboutPreview() {
    final category = data['category']?.toString() ?? '';
    final title = data['title']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final pillars = (data['pillars'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.isNotEmpty) ...[
          Text(
            category,
            style: AppTypography.bodySmall(color: AppColors.primaryGold)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
        ],
        Text(title, style: AppTypography.headingSmall()),
        const SizedBox(height: 8),
        Text(description, style: AppTypography.bodyMedium()),
        const SizedBox(height: 20),
        for (final p in pillars) ...[
          if (p is Map)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.softGoldBg,
                    child: Icon(
                      _getIconData(p['icon']?.toString()),
                      color: AppColors.primaryGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['title']?.toString() ?? '',
                            style: AppTypography.titleMedium()),
                        const SizedBox(height: 4),
                        Text(p['description']?.toString() ?? '',
                            style: AppTypography.bodyMedium()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // 4. COURSES PREVIEW
  Widget _buildCoursesPreview() {
    return _buildCollectionCardPreview(
      tag: data['tag']?.toString() ?? 'Course',
      title: data['title']?.toString() ?? 'Course Title',
      subtitle: data['subtitle']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      highlights: (data['highlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      icon: _getIconData(data['icon']?.toString()),
      isFeatured: data['isFeatured'] == true,
      order: data['order']?.toString() ?? '1',
    );
  }

  // 5. SPECIAL PROGRAMS PREVIEW
  Widget _buildProgramsPreview() {
    return _buildCollectionCardPreview(
      tag: data['tag']?.toString() ?? 'Special Program',
      title: data['title']?.toString() ?? 'Program Title',
      subtitle: data['subtitle']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      highlights: (data['highlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      icon: _getIconData(data['icon']?.toString()),
      isFeatured: data['isFeatured'] == true,
      order: data['order']?.toString() ?? '1',
    );
  }

  // 6. WHY NEXTGEN PREVIEW
  Widget _buildWhyNextGenPreview() {
    final title = data['title']?.toString() ?? 'Why NextGen';
    final subtitle = data['subtitle']?.toString() ?? '';
    final reasons = (data['reasons'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headingSmall()),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: AppTypography.bodySmall(color: AppColors.primaryGold)),
          ],
          const SizedBox(height: 18),
          for (final reason in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 20, color: AppColors.primaryGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reason.toString(),
                      style: AppTypography.bodyMedium(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 7. LEARNING MODES PREVIEW
  Widget _buildLearningModesPreview() {
    final modes = (data['modes'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['title']?.toString() ?? 'Flexible Learning Modes',
            style: AppTypography.headingSmall()),
        if (data['subtitle'] != null) ...[
          const SizedBox(height: 4),
          Text(data['subtitle'].toString(),
              style: AppTypography.bodySmall(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 20),
        for (final m in modes) ...[
          if (m is Map)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryNavy,
                        child: Icon(
                          _getIconData(m['icon']?.toString()),
                          color: AppColors.primaryGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['title']?.toString() ?? '',
                                style: AppTypography.titleMedium()),
                            if (m['badge'] != null)
                              Text(
                                m['badge'].toString(),
                                style: AppTypography.bodySmall(
                                    color: AppColors.primaryGold),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(m['description']?.toString() ?? '',
                      style: AppTypography.bodyMedium()),
                  if (m['image'] != null) ...[
                    const SizedBox(height: 12),
                    _buildImagePreview(m['image']?.toString(),
                        height: 140, label: '${m['title']} Image'),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }

  // 8. PLEDGE PREVIEW
  Widget _buildPledgePreview() {
    final category = data['category']?.toString() ?? 'PLEDGE';
    final title = data['title']?.toString() ?? '';
    final subtitle = data['subtitle']?.toString() ?? '';
    final pledgeImage = data['pledgeDocumentImage']?.toString();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            category,
            style: AppTypography.bodySmall(color: AppColors.primaryGold)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: AppTypography.headingSmall(), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(subtitle,
              style: AppTypography.bodyMedium(), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _buildImagePreview(pledgeImage,
              height: 220, label: 'Pledge Document / Certificate'),
        ],
      ),
    );
  }

  // 9. ASSESSMENTS PREVIEW
  Widget _buildAssessmentsPreview() {
    final cards = (data['evaluationCards'] as List?) ??
        (data['cards'] as List?) ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['title']?.toString() ?? 'Assessments & Academic Tracking',
            style: AppTypography.headingSmall()),
        const SizedBox(height: 6),
        Text(data['subtitle']?.toString() ?? '',
            style: AppTypography.bodyMedium()),
        const SizedBox(height: 18),
        for (int i = 0; i < cards.length; i++) ...[
          if (cards[i] is Map)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryNavy,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cards[i]['title']?.toString() ?? '',
                            style: AppTypography.titleMedium()),
                        const SizedBox(height: 4),
                        Text(
                          cards[i]['subtitle']?.toString() ??
                              cards[i]['description']?.toString() ??
                              '',
                          style: AppTypography.bodyMedium(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // 10. BANNER CTA PREVIEW
  Widget _buildBannerCtaPreview() {
    final mainHeading = data['mainHeading']?.toString() ?? '';
    final highlightedHeading = data['highlightedHeading']?.toString() ?? '';
    final badges = (data['badges'] as List?) ?? [];
    final buttonLabel = data['buttonLabel']?.toString() ?? 'Enquire Now';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mainHeading,
            style: AppTypography.headingMedium(color: AppColors.surfaceWhite),
          ),
          Text(
            highlightedHeading,
            style: AppTypography.headingMedium(color: AppColors.primaryGold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: badges.map((b) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  b.toString(),
                  style: AppTypography.bodySmall(color: AppColors.surfaceWhite),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.primaryNavy,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  // 11. GALLERY PREVIEW
  Widget _buildGalleryPreview() {
    final title = data['title']?.toString() ?? 'Gallery Item';
    final rawCategory = data['category']?.toString().trim();
    final rawTag = data['tag']?.toString().trim();
    final category = (rawCategory != null && rawCategory.isNotEmpty)
        ? rawCategory
        : ((rawTag != null && rawTag.isNotEmpty) ? rawTag : 'Campus');
    final description = data['description']?.toString() ?? '';
    final image = data['image']?.toString();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const Spacer(),
              Text('Order: ${data['order'] ?? 1}',
                  style: AppTypography.bodySmall(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTypography.headingSmall()),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: AppTypography.bodyMedium()),
          ],
          const SizedBox(height: 18),
          _buildImagePreview(image, height: 220, label: 'Gallery Photo'),
        ],
      ),
    );
  }

  // 12. FAQS PREVIEW
  Widget _buildFaqsPreview() {
    final question = data['question']?.toString() ?? data['title']?.toString() ?? 'FAQ Question';
    final answer = data['answer']?.toString() ?? data['description']?.toString() ?? '';
    final category = data['category']?.toString() ?? 'General';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.softBlueBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const Spacer(),
              Text('Order: ${data['order'] ?? 1}',
                  style: AppTypography.bodySmall(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Q: $question',
              style: AppTypography.headingSmall().copyWith(fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(answer, style: AppTypography.bodyMedium()),
          ),
        ],
      ),
    );
  }

  // 13. CONTACT & FOOTER PREVIEW
  Widget _buildContactPreview() {
    final phone1 = data['phone1']?.toString() ?? '';
    final phone2 = data['phone2']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final address = data['address']?.toString() ?? '';
    final brandDesc = data['brandDescription']?.toString() ?? '';
    final socialLinks = data['socialLinks'] as Map? ?? {};
    final quickLinks = (data['quickLinks'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Details & Brand Footer',
              style: AppTypography.headingSmall()),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone_outlined, color: AppColors.primaryNavy),
            title: const Text('Phone Numbers'),
            subtitle: Text('$phone1 ${phone2.isNotEmpty ? '/ $phone2' : ''}'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined, color: AppColors.primaryNavy),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined, color: AppColors.primaryNavy),
            title: const Text('Campus Address'),
            subtitle: Text(address),
          ),
          const SizedBox(height: 12),
          Text('Brand Footer Description:', style: AppTypography.titleMedium()),
          const SizedBox(height: 4),
          Text(brandDesc, style: AppTypography.bodyMedium()),
          const SizedBox(height: 18),
          Text('Social Links:', style: AppTypography.titleMedium()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: socialLinks.entries.map((e) {
              return Chip(
                avatar: const Icon(Icons.link, size: 16, color: AppColors.primaryNavy),
                label: Text('${e.key}: ${e.value}'),
                backgroundColor: AppColors.softBlueBg,
              );
            }).toList(),
          ),
          if (quickLinks.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Quick Navigation Links:', style: AppTypography.titleMedium()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: quickLinks.map((l) {
                final label = l is Map ? (l['label'] ?? '') : l.toString();
                return Chip(label: Text(label.toString()));
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // HELPER: Collection Item Card Preview (Courses & Programs)
  Widget _buildCollectionCardPreview({
    required String tag,
    required String title,
    required String subtitle,
    required String description,
    required List<String> highlights,
    required IconData icon,
    required bool isFeatured,
    required String order,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B1B3D),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryNavy,
                child: Icon(icon, color: AppColors.primaryGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headingSmall()),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: AppTypography.bodySmall(
                              color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Featured',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(description, style: AppTypography.bodyMedium()),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Curriculum Highlights:', style: AppTypography.titleMedium()),
            const SizedBox(height: 8),
            for (final hl in highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 16, color: AppColors.primaryGold),
                    const SizedBox(width: 8),
                    Expanded(child: Text(hl, style: AppTypography.bodySmall())),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // HELPER: Graceful Image Display with fallback
  Widget _buildImagePreview(String? imageUrl,
      {double height = 180, required String label}) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_outlined,
                  size: 28, color: AppColors.textSecondary),
              const SizedBox(height: 4),
              Text('No $label URL configured',
                  style: AppTypography.bodySmall(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final trimmed = imageUrl.trim();
    final isNetwork =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.softBlueBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isNetwork
            ? Image.network(
                trimmed,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => _buildErrorState(label),
              )
            : Image.asset(
                trimmed,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildErrorState(label),
              ),
      ),
    );
  }

  Widget _buildErrorState(String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined,
                size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              'Unable to load $label',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER: Icon mapper
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'groups_outlined':
        return Icons.groups_outlined;
      case 'person_search_outlined':
        return Icons.person_search_outlined;
      case 'edit_calendar_outlined':
        return Icons.edit_calendar_outlined;
      case 'notifications_none_outlined':
        return Icons.notifications_none_outlined;
      case 'verified_user_outlined':
        return Icons.verified_user_outlined;
      case 'star_outline_rounded':
        return Icons.star_outline_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'record_voice_over_rounded':
        return Icons.record_voice_over_rounded;
      case 'sentiment_very_satisfied_rounded':
        return Icons.sentiment_very_satisfied_rounded;
      case 'auto_graph_rounded':
        return Icons.auto_graph_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'school_rounded':
        return Icons.school_rounded;
      case 'desktop_windows_rounded':
        return Icons.desktop_windows_rounded;
      case 'edit_note_rounded':
        return Icons.edit_note_rounded;
      case 'calculate_rounded':
        return Icons.calculate_rounded;
      case 'business_outlined':
        return Icons.business_outlined;
      case 'devices_outlined':
        return Icons.devices_outlined;
      case 'assignment_outlined':
        return Icons.assignment_outlined;
      case 'calendar_month_outlined':
        return Icons.calendar_month_outlined;
      case 'replay_circle_filled_outlined':
        return Icons.replay_circle_filled_outlined;
      default:
        return Icons.star_rounded;
    }
  }

  Widget _buildGenericCardPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: AppTypography.headingSmall()),
          const Divider(height: 20),
          for (final entry in data.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(entry.value.toString())),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
