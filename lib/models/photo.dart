/// Represents a photo reference for a plumage.
///
/// Photos are NOT embedded in the database - this stores metadata only.
/// The URL points to external sources (Macaulay Library, iNaturalist).
///
/// Photos are fetched and cached on-device for offline use based on
/// user preferences (see regional photo downloads).
///
/// All photos must have open licenses (CC BY, CC BY-SA, Public Domain).
class Photo {
  /// Database ID (null for new records)
  final int? id;

  /// Foreign key to the plumage this photo depicts
  final int plumageId;

  /// URL to the photo on the external source
  final String url;

  /// Photographer name (null if not available)
  final String? photographer;

  /// License type (e.g., "CC BY 4.0", "Public Domain")
  final String license;

  /// Source of the photo (e.g., "Macaulay Library", "iNaturalist")
  final String source;

  Photo({
    this.id,
    required this.plumageId,
    required this.url,
    this.photographer,
    required this.license,
    required this.source,
  });

  /// Creates a Photo from a database row map.
  ///
  /// Maps snake_case column names to camelCase properties.
  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as int?,
      plumageId: map['plumage_id'] as int,
      url: map['url'] as String,
      photographer: map['photographer'] as String?,
      license: map['license'] as String,
      source: map['source'] as String,
    );
  }

  /// Converts this Photo to a database row map.
  ///
  /// Maps camelCase properties to snake_case column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plumage_id': plumageId,
      'url': url,
      'photographer': photographer,
      'license': license,
      'source': source,
    };
  }
}
