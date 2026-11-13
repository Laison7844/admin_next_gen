import 'package:flutter/material.dart';
import '../../content/models/content_type.dart';
import '../constants/home_default_data.dart';

enum HomeSectionKind {
  singleton,
  collection,
}

class HomeSectionDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final HomeSectionKind kind;
  final ContentType contentType;
  final Map<String, dynamic> defaultSingletonData;

  const HomeSectionDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.kind,
    required this.contentType,
    this.defaultSingletonData = const {},
  });

  bool get isSingleton => kind == HomeSectionKind.singleton;
  bool get isCollection => kind == HomeSectionKind.collection;

  static const List<HomeSectionDefinition> sections = [
    HomeSectionDefinition(
      id: 'home_hero',
      title: 'Hero Section',
      description: 'Main titles, subheadings, CTA buttons, and feature chips.',
      icon: Icons.view_carousel_outlined,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: HomeDefaultData.hero,
    ),
    HomeSectionDefinition(
      id: 'feature_highlights',
      title: 'Feature Highlights',
      description: 'Six core highlights (1-1 Attention, Tests, Guidance).',
      icon: Icons.featured_play_list_outlined,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: {'features': HomeDefaultData.featureHighlights},
    ),
    HomeSectionDefinition(
      id: 'about_us',
      title: 'About Us',
      description: 'Academy mission, values, and the four learning pillars.',
      icon: Icons.info_outline,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: HomeDefaultData.about,
    ),
    HomeSectionDefinition(
      id: 'courses',
      title: 'Courses',
      description: 'Foundation and Secondary curriculum courses (Classes 1–10).',
      icon: Icons.menu_book_outlined,
      kind: HomeSectionKind.collection,
      contentType: ContentType.courses,
    ),
    HomeSectionDefinition(
      id: 'programs',
      title: 'Special Programs',
      description: 'Spoken English, Handwriting, Abacus, 1-to-1 Special Care.',
      icon: Icons.school_outlined,
      kind: HomeSectionKind.collection,
      contentType: ContentType.programs,
    ),
    HomeSectionDefinition(
      id: 'why_nextgen',
      title: 'Why NextGen',
      description: 'Key differentiators, concept clarity, and teaching values.',
      icon: Icons.psychology_outlined,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: HomeDefaultData.whyNextGen,
    ),
    HomeSectionDefinition(
      id: 'learning_modes',
      title: 'Learning Modes',
      description: 'Interactive Offline Campus and Live Online Classroom modes.',
      icon: Icons.devices_outlined,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: HomeDefaultData.learningModes,
    ),
    HomeSectionDefinition(
      id: 'pledge',
      title: 'Pledge',
      description: 'Solemn commitment to student and parent success.',
      icon: Icons.handshake_outlined,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: HomeDefaultData.pledge,
    ),
    HomeSectionDefinition(
      id: 'assessments',
      title: 'Assessments & Progress',
      description: 'Weekly tests, progress reports, and parent meetings.',
      icon: Icons.assignment_outlined,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: HomeDefaultData.assessments,
    ),
    HomeSectionDefinition(
      id: 'banner_cta',
      title: 'Banner CTA',
      description: 'Admissions open banner, incentive badges, and action link.',
      icon: Icons.campaign_outlined,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: HomeDefaultData.bannerCta,
    ),
    HomeSectionDefinition(
      id: 'gallery',
      title: 'Gallery',
      description: 'Campus photographs, computer labs, and activity photos.',
      icon: Icons.photo_library_outlined,
      kind: HomeSectionKind.collection,
      contentType: ContentType.gallery,
    ),
    HomeSectionDefinition(
      id: 'faqs',
      title: 'FAQs',
      description: 'Frequently asked parent and student queries.',
      icon: Icons.quiz_outlined,
      kind: HomeSectionKind.collection,
      contentType: ContentType.faqs,
    ),
    HomeSectionDefinition(
      id: 'contact_footer',
      title: 'Contact & Footer',
      description: 'Official phone numbers, emails, addresses, and social links.',
      icon: Icons.contact_mail_outlined,
      kind: HomeSectionKind.singleton,
      contentType: ContentType.siteSections,
      defaultSingletonData: HomeDefaultData.contactFooter,
    ),
  ];

  /// Finds a [HomeSectionDefinition] by its unique [id], or returns `null` if not found.
  static HomeSectionDefinition? findById(String id) {
    for (final section in sections) {
      if (section.id == id) {
        return section;
      }
    }
    return null;
  }

  /// Retrieves a [HomeSectionDefinition] by its unique [id].
  /// Throws [ArgumentError] if the id is not recognized.
  static HomeSectionDefinition getById(String id) {
    final section = findById(id);
    if (section == null) {
      throw ArgumentError.value(
        id,
        'id',
        'No HomeSectionDefinition found with id "$id". Expected one of: ${sections.map((s) => s.id).join(', ')}',
      );
    }
    return section;
  }
}

