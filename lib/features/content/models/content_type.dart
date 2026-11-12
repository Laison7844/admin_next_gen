/// Supported content types managed by the CMS.
enum ContentType {
  courses('courses', 'Courses', 'courses'),
  programs('programs', 'Programs', 'programs'),
  faqs('faqs', 'FAQs', 'faqs'),
  testimonials('testimonials', 'Testimonials', 'testimonials'),
  gallery('gallery', 'Gallery', 'gallery'),
  siteSections('site_sections', 'Site Sections', 'site_sections');

  final String key;
  final String displayName;
  final String publicCollection;

  const ContentType(this.key, this.displayName, this.publicCollection);

  static ContentType fromKey(String key) {
    for (final type in ContentType.values) {
      if (type.key == key || type.publicCollection == key) {
        return type;
      }
    }
    return ContentType.courses;
  }
}

