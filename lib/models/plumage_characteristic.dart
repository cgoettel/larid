/// Junction table linking plumages to their observable characteristics.
///
/// Represents the many-to-many relationship between plumages and
/// characteristic values. For example:
/// - "Adult Western Gull breeding" has pink legs (characteristic_value)
/// - "Adult Western Gull breeding" has yellow bill (characteristic_value)
/// - etc.
///
/// This is the core data structure for the filtering logic.
class PlumageCharacteristic {
  /// Foreign key to the plumage
  final int plumageId;

  /// Foreign key to the characteristic value
  final int characteristicValueId;

  PlumageCharacteristic({
    required this.plumageId,
    required this.characteristicValueId,
  });

  /// Creates a PlumageCharacteristic from a database row map.
  ///
  /// Maps snake_case column names to camelCase properties.
  factory PlumageCharacteristic.fromMap(Map<String, dynamic> map) {
    return PlumageCharacteristic(
      plumageId: map['plumage_id'] as int,
      characteristicValueId: map['characteristic_value_id'] as int,
    );
  }

  /// Converts this PlumageCharacteristic to a database row map.
  ///
  /// Maps camelCase properties to snake_case column names.
  Map<String, dynamic> toMap() {
    return {
      'plumage_id': plumageId,
      'characteristic_value_id': characteristicValueId,
    };
  }
}
