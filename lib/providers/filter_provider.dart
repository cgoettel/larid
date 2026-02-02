import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/characteristic.dart';
import '../models/characteristic_value.dart';
import '../models/plumage.dart';
import '../models/species.dart';
import '../services/database_service.dart';

/// Result item combining plumage and species information for display.
class PlumageResult {
  final Plumage plumage;
  final Species species;

  /// Occurrence level in selected region (common/uncommon/rare).
  /// Null when no region is selected.
  final String? occurrence;

  PlumageResult({
    required this.plumage,
    required this.species,
    this.occurrence,
  });
}

/// Provider managing filter state and real-time results for gull identification.
///
/// Handles user filter selections (characteristic values) and provides
/// filtered results by querying plumages that match ALL selected criteria.
class FilterProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // SharedPreferences keys (must match settings_screen.dart)
  static const String _keyRegionId = 'selected_region_id';
  static const String _keyShowOnlyCommon = 'show_only_common_species';

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

  /// Region filter settings
  int? _selectedRegionId;
  bool _showOnlyCommon = false;

  /// Cached species for the selected region (with occurrence levels)
  Map<int, String?> _speciesOccurrences = {};

  // Getters
  List<Characteristic> get characteristics => _characteristics;
  Map<int, List<CharacteristicValue>> get characteristicValues =>
      _characteristicValues;
  Map<int, Set<int>> get selectedValues => _selectedValues;
  List<PlumageResult> get results => _results;
  bool get isLoading => _isLoading;
  bool get hasActiveFilters => _selectedValues.isNotEmpty;
  int? get selectedRegionId => _selectedRegionId;
  bool get showOnlyCommon => _showOnlyCommon;

  /// Initializes the provider by loading characteristics, values, and region settings.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load region settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _selectedRegionId = prefs.getInt(_keyRegionId);
      _showOnlyCommon = prefs.getBool(_keyShowOnlyCommon) ?? false;

      // Load species for selected region (caches occurrence levels)
      await _loadRegionSpecies();

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

  /// Reloads region settings from SharedPreferences and refreshes results.
  ///
  /// Call this when returning from settings screen to pick up any changes.
  Future<void> refreshRegionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final newRegionId = prefs.getInt(_keyRegionId);
    final newShowOnlyCommon = prefs.getBool(_keyShowOnlyCommon) ?? false;

    // Only reload if settings changed
    if (newRegionId != _selectedRegionId ||
        newShowOnlyCommon != _showOnlyCommon) {
      _selectedRegionId = newRegionId;
      _showOnlyCommon = newShowOnlyCommon;
      await _loadRegionSpecies();
      await _loadResults();
      notifyListeners();
    }
  }

  /// Loads and caches species for the selected region.
  Future<void> _loadRegionSpecies() async {
    final speciesWithOccurrence = await _db.getSpeciesForRegion(
      _selectedRegionId,
      showOnlyCommon: _showOnlyCommon,
    );

    _speciesOccurrences = {
      for (final swo in speciesWithOccurrence)
        swo.species.id!: swo.occurrence,
    };
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

  /// Gets all plumages with their species information, filtered by region.
  Future<List<PlumageResult>> _getAllPlumages() async {
    final species = await _db.getAllSpecies();
    final results = <PlumageResult>[];

    for (final sp in species) {
      // Skip species not in the selected region
      if (!_speciesOccurrences.containsKey(sp.id)) {
        continue;
      }

      final plumages = await _db.getPlumagesBySpeciesId(sp.id!);
      for (final plumage in plumages) {
        results.add(PlumageResult(
          plumage: plumage,
          species: sp,
          occurrence: _speciesOccurrences[sp.id],
        ));
      }
    }

    return results;
  }

  /// Loads species information for a list of plumages, filtered by region.
  Future<List<PlumageResult>> _loadSpeciesForPlumages(
      List<Plumage> plumages) async {
    final results = <PlumageResult>[];

    for (final plumage in plumages) {
      // Skip plumages for species not in the selected region
      if (!_speciesOccurrences.containsKey(plumage.speciesId)) {
        continue;
      }

      final species = await _db.getSpeciesById(plumage.speciesId);
      if (species != null) {
        results.add(PlumageResult(
          plumage: plumage,
          species: species,
          occurrence: _speciesOccurrences[species.id],
        ));
      }
    }

    return results;
  }
}
