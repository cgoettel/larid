import 'package:flutter/foundation.dart';
import '../models/characteristic.dart';
import '../models/characteristic_value.dart';
import '../models/plumage.dart';
import '../models/species.dart';
import '../services/database_service.dart';

/// Result item combining plumage and species information for display.
class PlumageResult {
  final Plumage plumage;
  final Species species;

  PlumageResult({required this.plumage, required this.species});
}

/// Provider managing filter state and real-time results for gull identification.
///
/// Handles user filter selections (characteristic values) and provides
/// filtered results by querying plumages that match ALL selected criteria.
class FilterProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  /// All available characteristics for filtering
  List<Characteristic> _characteristics = [];

  /// All characteristic values grouped by characteristic ID
  final Map<int, List<CharacteristicValue>> _characteristicValues = {};

  /// Selected characteristic value IDs grouped by characteristic ID
  /// Example: {1: {5, 7}, 2: {12}} means characteristic 1 has values 5,7 selected
  final Map<int, Set<int>> _selectedValues = {};

  /// Filtered results matching current filter criteria
  List<PlumageResult> _results = [];

  /// Loading state
  bool _isLoading = false;

  // Getters
  List<Characteristic> get characteristics => _characteristics;
  Map<int, List<CharacteristicValue>> get characteristicValues =>
      _characteristicValues;
  Map<int, Set<int>> get selectedValues => _selectedValues;
  List<PlumageResult> get results => _results;
  bool get isLoading => _isLoading;
  bool get hasActiveFilters => _selectedValues.isNotEmpty;

  /// Initializes the provider by loading characteristics and values.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all characteristics
      _characteristics = await _db.getAllCharacteristics();

      // Load all characteristic values for each characteristic
      for (final characteristic in _characteristics) {
        final values = await _db
            .getCharacteristicValuesByCharacteristicId(characteristic.id!);
        _characteristicValues[characteristic.id!] = values;
      }

      // Load initial results (no filters = show all)
      await _loadResults();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates filter selection for a characteristic.
  ///
  /// Toggles the value selection for the given characteristic.
  /// If valueId is null, clears all selections for that characteristic.
  Future<void> updateFilter(int characteristicId, int? valueId) async {
    if (valueId == null) {
      _selectedValues.remove(characteristicId);
    } else {
      // For single-select dropdowns, replace the existing selection
      _selectedValues[characteristicId] = {valueId};
    }

    await _loadResults();
    notifyListeners();
  }

  /// Clears all active filters.
  Future<void> clearFilters() async {
    _selectedValues.clear();
    await _loadResults();
    notifyListeners();
  }

  /// Loads results matching current filter criteria.
  ///
  /// Implements AND logic: plumages must match ALL selected characteristic values.
  /// If no filters are active, shows all plumages.
  Future<void> _loadResults() async {
    if (_selectedValues.isEmpty) {
      // No filters - show all plumages
      _results = await _getAllPlumages();
      return;
    }

    // Get all selected value IDs
    final selectedValueIds = _selectedValues.values
        .expand((valueSet) => valueSet)
        .toList();

    if (selectedValueIds.isEmpty) {
      _results = [];
      return;
    }

    // Query plumages matching ALL selected values
    final db = await _db.database;

    // Build query with placeholders for IN clause
    final placeholders = List.filled(selectedValueIds.length, '?').join(',');
    final numFilters = selectedValueIds.length;

    final query = '''
      SELECT DISTINCT p.*
      FROM plumages p
      INNER JOIN plumage_characteristics pc ON p.id = pc.plumage_id
      WHERE pc.characteristic_value_id IN ($placeholders)
      GROUP BY p.id
      HAVING COUNT(DISTINCT pc.characteristic_value_id) = ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      query,
      [...selectedValueIds, numFilters],
    );

    // Convert to Plumage objects and fetch species data
    final plumages = maps.map((map) => Plumage.fromMap(map)).toList();
    _results = await _loadSpeciesForPlumages(plumages);
  }

  /// Gets all plumages with their species information.
  Future<List<PlumageResult>> _getAllPlumages() async {
    final species = await _db.getAllSpecies();
    final results = <PlumageResult>[];

    for (final sp in species) {
      final plumages = await _db.getPlumagesBySpeciesId(sp.id!);
      for (final plumage in plumages) {
        results.add(PlumageResult(plumage: plumage, species: sp));
      }
    }

    return results;
  }

  /// Loads species information for a list of plumages.
  Future<List<PlumageResult>> _loadSpeciesForPlumages(
      List<Plumage> plumages) async {
    final results = <PlumageResult>[];

    for (final plumage in plumages) {
      final species = await _db.getSpeciesById(plumage.speciesId);
      if (species != null) {
        results.add(PlumageResult(plumage: plumage, species: species));
      }
    }

    return results;
  }
}
