/// Content lifecycle status indicating whether an item has an active
/// published counterpart in public website collections.
enum PublishStatus {
  draft('draft', 'Draft'),
  published('published', 'Published');

  final String key;
  final String label;

  const PublishStatus(this.key, this.label);

  bool get isDraft => this == PublishStatus.draft;
  bool get isPublished => this == PublishStatus.published;

  static PublishStatus fromKey(String? key) {
    if (key == 'published') return PublishStatus.published;
    return PublishStatus.draft;
  }
}

