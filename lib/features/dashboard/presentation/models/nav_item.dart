import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../routing/route_paths.dart';

class NavItem {
  final String title;
  final IconData icon;
  final String route;
  final String description;
  final String group;

  const NavItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.description,
    this.group = 'WEBSITE CONTENT',
  });

  static const String groupOverview = 'OVERVIEW';
  static const String groupWebsiteContent = 'WEBSITE CONTENT';
  static const String groupEnquiriesMedia = 'ENQUIRIES & MEDIA';
  static const String groupGeneral = 'GENERAL';

  static const List<NavItem> items = [
    // OVERVIEW
    NavItem(
      title: AppStrings.navDashboard,
      icon: Icons.dashboard_outlined,
      route: RoutePaths.dashboard,
      description: 'System metrics, academy overview and quick links',
      group: groupOverview,
    ),

    // WEBSITE CONTENT
    NavItem(
      title: AppStrings.navHome,
      icon: Icons.home_outlined,
      route: RoutePaths.home,
      description: 'Homepage content sections, hero and banners',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navAbout,
      icon: Icons.info_outline,
      route: RoutePaths.about,
      description: 'Academy mission, values, and educational pillars',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navCourses,
      icon: Icons.menu_book_outlined,
      route: RoutePaths.courses,
      description: 'Curriculum listings, classes 1 to 10 foundation courses',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navPrograms,
      icon: Icons.school_outlined,
      route: RoutePaths.programs,
      description: 'Specialized programs (Spoken English, Abacus, etc.)',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navWhyNextGen,
      icon: Icons.psychology_outlined,
      route: RoutePaths.whyNextGen,
      description: 'Key differentiators, concept clarity, and values',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navLearningModes,
      icon: Icons.devices_outlined,
      route: RoutePaths.learningModes,
      description: 'Offline campus and online classroom options',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navPledge,
      icon: Icons.handshake_outlined,
      route: RoutePaths.pledge,
      description: 'Commitment to student and parent success',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navAssessments,
      icon: Icons.assignment_outlined,
      route: RoutePaths.assessments,
      description: 'Weekly tests, progress reports, and review meetings',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navBannerCta,
      icon: Icons.campaign_outlined,
      route: RoutePaths.bannerCta,
      description: 'Admissions open banner, incentive badges, and CTA',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navGallery,
      icon: Icons.photo_library_outlined,
      route: RoutePaths.gallery,
      description: 'Campus photo collections and activity photo albums',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navTestimonials,
      icon: Icons.rate_review_outlined,
      route: RoutePaths.testimonials,
      description: 'Student achievements and parent recommendations',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navFaqs,
      icon: Icons.quiz_outlined,
      route: RoutePaths.faqs,
      description: 'Frequently asked parent and student admission queries',
      group: groupWebsiteContent,
    ),
    NavItem(
      title: AppStrings.navContactFooter,
      icon: Icons.contact_mail_outlined,
      route: RoutePaths.contactFooter,
      description: 'Official phone numbers, email, addresses, and footer info',
      group: groupWebsiteContent,
    ),

    // ENQUIRIES & MEDIA
    NavItem(
      title: AppStrings.navEnquiries,
      icon: Icons.mail_outline,
      route: RoutePaths.enquiries,
      description: 'Prospective student leads and admissions submissions',
      group: groupEnquiriesMedia,
    ),
    NavItem(
      title: AppStrings.navMediaLibrary,
      icon: Icons.perm_media_outlined,
      route: RoutePaths.mediaLibrary,
      description: 'Media asset library for website images',
      group: groupEnquiriesMedia,
    ),

    // GENERAL
    NavItem(
      title: AppStrings.navSettings,
      icon: Icons.settings_outlined,
      route: RoutePaths.settings,
      description: 'Contact details, social links, and website settings',
      group: groupGeneral,
    ),
  ];

  static Map<String, List<NavItem>> get groupedItems {
    final map = <String, List<NavItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.group, () => []).add(item);
    }
    return map;
  }
}
