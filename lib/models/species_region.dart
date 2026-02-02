/// Junction table linking species to regions with occurrence frequency.
///
/// Represents the many-to-many relationship between species and regions,
/// including how common each species is in each region.
///
/// Example: Western Gull is "common" in California but "rare" in Nevada.
class SpeciesRegion {
  /// Foreign key to the species
  final int speciesId;

  /// Foreign key to the region
  final int regionId;

  /// Occurrence frequency (e.g., "common", "uncommon", "rare")
  final String? occurrence;

  SpeciesRegion({
    required this.speciesId,
    required this.regionId,
    this.occurrence,
  });

  /// Creates a SpeciesRegion from a database row map.
  ///
  /// Maps snake_case column names to camelCase properties.
  factory SpeciesRegion.fromMap(Map<String, dynamic> map) {
    return SpeciesRegion(
      speciesId: map['species_id'] as int,
      regionId: map['region_id'] as int,
      occurrence: map['occurrence'] as String?,
    );
  }

  /// Converts this SpeciesRegion to a database row map.
  ///
  /// Maps camelCase properties to snake_case column names.
  Map<String, dynamic> toMap() {
    return {
      'species_id': speciesId,
      'region_id': regionId,
      'occurrence': occurrence,
    };
  }
}
