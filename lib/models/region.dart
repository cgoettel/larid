/// Represents a geographic region in a hierarchical structure.
///
/// Regions allow filtering species by location and support hierarchical
/// relationships. For example:
/// - California (parent)
///   - Northern California (child)
///   - Central California (child)
///   - Southern California (child)
///
/// Used for regional photo downloads and occurrence filtering.
class Region {
  /// Database ID (null for new records)
  final int? id;

  /// Region name (e.g., "California", "Northern California")
  final String name;

  /// Type of region (e.g., "state", "subregion"), null if not specified
  final String? regionType;

  /// Foreign key to parent region (null for top-level regions)
  final int? parentRegionId;

  Region({
    this.id,
    required this.name,
    this.regionType,
    this.parentRegionId,
  });

  /// Creates a Region from a database row map.
  ///
  /// Maps snake_case column names to camelCase properties.
  factory Region.fromMap(Map<String, dynamic> map) {
    return Region(
      id: map['id'] as int?,
      name: map['name'] as String,
      regionType: map['region_type'] as String?,
      parentRegionId: map['parent_region_id'] as int?,
    );
  }

  /// Converts this Region to a database row map.
  ///
  /// Maps camelCase properties to snake_case column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'region_type': regionType,
      'parent_region_id': parentRegionId,
    };
  }
}
