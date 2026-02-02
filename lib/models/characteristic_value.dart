/// Represents a possible value for a characteristic.
///
/// For example, for the "leg_color" characteristic, values include
/// "pink", "yellow", "gray", etc.
///
/// Each plumage is linked to multiple characteristic values via
/// the [PlumageCharacteristic] junction table.
class CharacteristicValue {
  /// Database ID (null for new records)
  final int? id;

  /// Foreign key to the characteristic this value belongs to
  final int characteristicId;

  /// Internal value name (e.g., "pink")
  final String value;

  /// User-facing display name (e.g., "Pink")
  final String displayName;

  CharacteristicValue({
    this.id,
    required this.characteristicId,
    required this.value,
    required this.displayName,
  });

  /// Creates a CharacteristicValue from a database row map.
  ///
  /// Maps snake_case column names to camelCase properties.
  factory CharacteristicValue.fromMap(Map<String, dynamic> map) {
    return CharacteristicValue(
      id: map['id'] as int?,
      characteristicId: map['characteristic_id'] as int,
      value: map['value'] as String,
      displayName: map['display_name'] as String,
    );
  }

  /// Converts this CharacteristicValue to a database row map.
  ///
  /// Maps camelCase properties to snake_case column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'characteristic_id': characteristicId,
      'value': value,
      'display_name': displayName,
    };
  }
}
