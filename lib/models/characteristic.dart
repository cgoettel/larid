/// Represents an observable characteristic type used for identification.
///
/// Characteristics are the categories of features birders observe
/// (e.g., "leg_color", "bill_pattern", "head_color").
///
/// Each characteristic has multiple possible values (see [CharacteristicValue]).
class Characteristic {
  /// Database ID (null for new records)
  final int? id;

  /// Internal name (e.g., "leg_color")
  final String name;

  /// User-facing display name (e.g., "Leg Color")
  final String displayName;

  /// Order for displaying characteristics in the UI
  final int? displayOrder;

  Characteristic({
    this.id,
    required this.name,
    required this.displayName,
    this.displayOrder,
  });

  /// Creates a Characteristic from a database row map.
  ///
  /// Maps snake_case column names to camelCase properties.
  factory Characteristic.fromMap(Map<String, dynamic> map) {
    return Characteristic(
      id: map['id'] as int?,
      name: map['name'] as String,
      displayName: map['display_name'] as String,
      displayOrder: map['display_order'] as int?,
    );
  }

  /// Converts this Characteristic to a database row map.
  ///
  /// Maps camelCase properties to snake_case column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'display_order': displayOrder,
    };
  }
}
