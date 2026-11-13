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

  /// Resolves a [ContentType] from its string [key], public collection name, or enum name.
  /// Throws [ArgumentError] if the key does not match any valid content type.
  static ContentType fromKey(String key) {
    for (final type in ContentType.values) {
      if (type.key == key || type.publicCollection == key || type.name == key) {
        return type;
      }
    }
    throw ArgumentError.value(
      key,
      'contentType',
      'Unknown content type "$key". Expected one of: ${ContentType.values.map((v) => v.key).join(', ')}',
    );
  }

  /// Safe lookup returning null if invalid instead of throwing.
  static ContentType? tryFromKey(String? key) {
    if (key == null) return null;
    for (final type in ContentType.values) {
      if (type.key == key || type.publicCollection == key || type.name == key) {
        return type;
      }
    }
    return null;
  }
}

