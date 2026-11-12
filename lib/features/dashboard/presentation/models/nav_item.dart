import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../routing/route_paths.dart';

class NavItem {
  final String title;
  final IconData icon;
  final String route;
  final String description;

  const NavItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.description,
  });

  static const List<NavItem> items = [
    NavItem(
      title: AppStrings.navDashboard,
      icon: Icons.dashboard_outlined,
      route: RoutePaths.dashboard,
      description: 'System metrics, academy overview and quick links',
    ),
    NavItem(
      title: AppStrings.navHome,
      icon: Icons.home_outlined,
      route: RoutePaths.home,
      description: 'Hero banners, statistics counters, CTA and homepage sections',
    ),
    NavItem(
      title: AppStrings.navAbout,
      icon: Icons.info_outline,
      route: RoutePaths.about,
      description: 'Academy mission, leadership, faculty and historical milestone content',
    ),
    NavItem(
      title: AppStrings.navCourses,
      icon: Icons.menu_book_outlined,
      route: RoutePaths.courses,
      description: 'Curriculum listings, schedules, age groups and syllabus downloads',
    ),
    NavItem(
      title: AppStrings.navPrograms,
      icon: Icons.school_outlined,
      route: RoutePaths.programs,
      description: 'Specialized programs, certifications and workshop schedules',
    ),
    NavItem(
      title: AppStrings.navGallery,
      icon: Icons.photo_library_outlined,
      route: RoutePaths.gallery,
      description: 'Campus photo collections, event albums and category tagging',
    ),
    NavItem(
      title: AppStrings.navTestimonials,
      icon: Icons.rate_review_outlined,
      route: RoutePaths.testimonials,
      description: 'Student achievements, parent testimonials and alumni endorsements',
    ),
    NavItem(
      title: AppStrings.navFaqs,
      icon: Icons.help_outline,
      route: RoutePaths.faqs,
      description: 'Frequently asked questions, admission queries and categorised answers',
    ),
    NavItem(
      title: AppStrings.navEnquiries,
      icon: Icons.mail_outline,
      route: RoutePaths.enquiries,
      description: 'Prospective student leads and contact form submissions',
    ),
    NavItem(
      title: AppStrings.navMediaLibrary,
      icon: Icons.perm_media_outlined,
      route: RoutePaths.mediaLibrary,
      description: 'Centralized repository for documents, brand assets and web media',
    ),
    NavItem(
      title: AppStrings.navSettings,
      icon: Icons.settings_outlined,
      route: RoutePaths.settings,
      description: 'Academy contact information, social links and CMS settings',
    ),
  ];
}

