/// Represents a gull species.
///
/// Each species has multiple plumage variations (age and seasonal),
/// regional occurrence data, and associated photos.
///
/// Example: Western Gull (Larus occidentalis) with adult breeding,
/// first-year, and other plumage variations.
class Species {
  /// Database ID (null for new records)
  final int? id;

  /// Common name (e.g., "Western Gull")
  final String commonName;

  /// Scientific name (e.g., "Larus occidentalis")
  final String scientificName;

  /// Taxonomic order for sorting species lists
  final int? taxonomicOrder;

  Species({
    this.id,
    required this.commonName,
    required this.scientificName,
    this.taxonomicOrder,
  });

  /// Creates a Species from a database row map.
  ///
  /// Maps snake_case column names to camelCase properties.
  factory Species.fromMap(Map<String, dynamic> map) {
    return Species(
      id: map['id'] as int?,
      commonName: map['common_name'] as String,
      scientificName: map['scientific_name'] as String,
      taxonomicOrder: map['taxonomic_order'] as int?,
    );
  }

  /// Converts this Species to a database row map.
  ///
  /// Maps camelCase properties to snake_case column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'common_name': commonName,
      'scientific_name': scientificName,
      'taxonomic_order': taxonomicOrder,
    };
  }
}
