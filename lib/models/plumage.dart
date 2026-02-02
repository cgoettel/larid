/// Represents a specific plumage variation of a species.
///
/// Gull plumages vary by age class (adult, first-year, second-year, etc.)
/// and season (breeding, non-breeding). Each plumage has distinct observable
/// characteristics used for identification.
///
/// Example: "Adult Western Gull in breeding plumage" - pink legs, yellow bill
/// with red spot, white head, dark gray back.
class Plumage {
  /// Database ID (null for new records)
  final int? id;

  /// Foreign key to the species this plumage belongs to
  final int speciesId;

  /// Age class (e.g., "adult", "first-year", "second-year")
  final String ageClass;

  /// Season (e.g., "breeding", "non-breeding"), null if not season-specific
  final String? season;

  /// Human-readable description of this plumage variation
  final String? description;

  Plumage({
    this.id,
    required this.speciesId,
    required this.ageClass,
    this.season,
    this.description,
  });

  /// Creates a Plumage from a database row map.
  ///
  /// Maps snake_case column names to camelCase properties.
  factory Plumage.fromMap(Map<String, dynamic> map) {
    return Plumage(
      id: map['id'] as int?,
      speciesId: map['species_id'] as int,
      ageClass: map['age_class'] as String,
      season: map['season'] as String?,
      description: map['description'] as String?,
    );
  }

  /// Converts this Plumage to a database row map.
  ///
  /// Maps camelCase properties to snake_case column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'species_id': speciesId,
      'age_class': ageClass,
      'season': season,
      'description': description,
    };
  }
}
