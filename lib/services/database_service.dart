import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/characteristic.dart';
import '../models/characteristic_value.dart';
import '../models/photo.dart';
import '../models/plumage.dart';
import '../models/plumage_characteristic.dart';
import '../models/region.dart';
import '../models/species.dart';
import '../models/species_region.dart';
import '../models/species_with_occurrence.dart';

/// Service for accessing the read-only gull identification database.
///
/// This service provides access to a pre-built SQLite database bundled with
/// the app. The database contains curated species, plumage, characteristic,
/// and photo data for gull identification.
///
/// **Read-only database**: This database is opened in read-only mode and
/// contains only curated data. It supports SELECT queries only - no writes.
/// Database updates are delivered via new app versions with updated database files.
///
/// **User data storage**: User preferences and settings should use
/// SharedPreferences, not this database. Photo caching is handled via the
/// file system, not the database.
///
/// Usage:
/// ```dart
/// final db = DatabaseService();
/// final species = await db.getAllSpecies();
/// ```
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Gets the database instance, initializing it if needed.
  ///
  /// On first access, copies the bundled database from assets to device storage
  /// and opens it in read-only mode.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database by copying from assets if needed.
  ///
  /// The database is bundled in assets/database/gull_id.db and copied to
  /// device storage on first run. Subsequent app launches reuse the existing
  /// copy. Database updates are delivered via new app versions.
  Future<Database> _initDatabase() async {
    // For desktop platforms (macOS, Linux, Windows), initialize FFI
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // For web platform, use sqflite_common_ffi_web
    if (kIsWeb) {
      // Initialize web database factory
      databaseFactory = databaseFactoryFfiWeb;

      // For web, we need to create and populate the database since we can't
      // easily copy the bundled one. For now, create an empty database.
      // TODO: Implement proper data loading for web (Issue #14)
      return await databaseFactory.openDatabase(
        'gull_id.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Create schema
            await db.execute('''
              CREATE TABLE species (
                id INTEGER PRIMARY KEY,
                common_name TEXT NOT NULL,
                scientific_name TEXT NOT NULL,
                taxonomic_order INTEGER
              )
            ''');
            await db.execute('''
              CREATE TABLE plumages (
                id INTEGER PRIMARY KEY,
                species_id INTEGER NOT NULL,
                age_class TEXT NOT NULL,
                season TEXT,
                description TEXT,
                FOREIGN KEY (species_id) REFERENCES species(id)
              )
            ''');
            await db.execute('''
              CREATE TABLE characteristics (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                display_name TEXT NOT NULL,
                display_order INTEGER
              )
            ''');
            await db.execute('''
              CREATE TABLE characteristic_values (
                id INTEGER PRIMARY KEY,
                characteristic_id INTEGER NOT NULL,
                value TEXT NOT NULL,
                display_name TEXT NOT NULL,
                FOREIGN KEY (characteristic_id) REFERENCES characteristics(id)
              )
            ''');
            await db.execute('''
              CREATE TABLE plumage_characteristics (
                id INTEGER PRIMARY KEY,
                plumage_id INTEGER NOT NULL,
                characteristic_value_id INTEGER NOT NULL,
                FOREIGN KEY (plumage_id) REFERENCES plumages(id),
                FOREIGN KEY (characteristic_value_id) REFERENCES characteristic_values(id)
              )
            ''');
            await db.execute('''
              CREATE TABLE photos (
                id INTEGER PRIMARY KEY,
                plumage_id INTEGER NOT NULL,
                url TEXT NOT NULL,
                photographer TEXT,
                license TEXT,
                source TEXT,
                FOREIGN KEY (plumage_id) REFERENCES plumages(id)
              )
            ''');
            await db.execute('''
              CREATE TABLE regions (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                parent_region_id INTEGER,
                FOREIGN KEY (parent_region_id) REFERENCES regions(id)
              )
            ''');
            await db.execute('''
              CREATE TABLE species_regions (
                id INTEGER PRIMARY KEY,
                species_id INTEGER NOT NULL,
                region_id INTEGER NOT NULL,
                occurrence TEXT,
                FOREIGN KEY (species_id) REFERENCES species(id),
                FOREIGN KEY (region_id) REFERENCES regions(id)
              )
            ''');

            // Insert sample data from the bundled database
            // TODO: Load data from assets/database/gull_id.db or remote source
            await db.insert('species', {
              'id': 1,
              'common_name': 'Western Gull',
              'scientific_name': 'Larus occidentalis',
              'taxonomic_order': 1
            });
            await db.insert('species', {
              'id': 2,
              'common_name': 'California Gull',
              'scientific_name': 'Larus californicus',
              'taxonomic_order': 2
            });
            await db.insert('plumages', {
              'id': 1,
              'species_id': 1,
              'age_class': 'adult',
              'season': 'breeding'
            });
            await db.insert('plumages', {
              'id': 2,
              'species_id': 2,
              'age_class': 'adult',
              'season': 'breeding'
            });
          },
        ),
      );
    }

    // For mobile/desktop platforms
    // Get the path to store the database
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'gull_id.db');

    // Check if database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Copy from assets
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Load database from asset and copy
      ByteData data = await rootBundle.load('assets/database/gull_id.db');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    // Open the database in read-only mode
    // Note: Don't specify version for read-only databases (version writes PRAGMA)
    return await openDatabase(
      path,
      readOnly: true,
    );
  }

  // Species queries

  /// Gets all species, ordered by taxonomic order and common name.
  ///
  /// Returns a list of all gull species in the database.
  Future<List<Species>> getAllSpecies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('species',
        orderBy: 'taxonomic_order ASC, common_name ASC');
    return List.generate(maps.length, (i) => Species.fromMap(maps[i]));
  }

  /// Gets a single species by ID.
  ///
  /// Returns null if no species with the given ID exists.
  Future<Species?> getSpeciesById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'species',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Species.fromMap(maps.first);
  }

  // Plumage queries

  /// Gets all plumages for a given species.
  ///
  /// Returns plumages representing different age classes and seasonal variations
  /// (e.g., adult breeding, first-year, etc.).
  Future<List<Plumage>> getPlumagesBySpeciesId(int speciesId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plumages',
      where: 'species_id = ?',
      whereArgs: [speciesId],
    );
    return List.generate(maps.length, (i) => Plumage.fromMap(maps[i]));
  }

  /// Gets a single plumage by ID.
  ///
  /// Returns null if no plumage with the given ID exists.
  Future<Plumage?> getPlumageById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plumages',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Plumage.fromMap(maps.first);
  }

  // Characteristic queries

  /// Gets all characteristics, ordered by display order.
  ///
  /// Returns observable features used for identification (leg color, bill pattern, etc.).
  Future<List<Characteristic>> getAllCharacteristics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('characteristics', orderBy: 'display_order ASC');
    return List.generate(maps.length, (i) => Characteristic.fromMap(maps[i]));
  }

  /// Gets a single characteristic by ID.
  ///
  /// Returns null if no characteristic with the given ID exists.
  Future<Characteristic?> getCharacteristicById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'characteristics',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Characteristic.fromMap(maps.first);
  }

  // CharacteristicValue queries

  /// Gets all possible values for a given characteristic.
  ///
  /// For example, for the "leg_color" characteristic, returns values like
  /// "pink", "yellow", "gray", etc.
  Future<List<CharacteristicValue>> getCharacteristicValuesByCharacteristicId(
      int characteristicId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'characteristic_values',
      where: 'characteristic_id = ?',
      whereArgs: [characteristicId],
    );
    return List.generate(
        maps.length, (i) => CharacteristicValue.fromMap(maps[i]));
  }

  /// Gets a single characteristic value by ID.
  ///
  /// Returns null if no characteristic value with the given ID exists.
  Future<CharacteristicValue?> getCharacteristicValueById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'characteristic_values',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CharacteristicValue.fromMap(maps.first);
  }

  // PlumageCharacteristic queries

  /// Gets all characteristic values associated with a plumage.
  ///
  /// Returns the junction table records linking a plumage to its observable
  /// characteristics (e.g., "adult Western Gull has pink legs, yellow bill").
  Future<List<PlumageCharacteristic>> getPlumageCharacteristicsByPlumageId(
      int plumageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plumage_characteristics',
      where: 'plumage_id = ?',
      whereArgs: [plumageId],
    );
    return List.generate(
        maps.length, (i) => PlumageCharacteristic.fromMap(maps[i]));
  }

  // Photo queries

  /// Gets all photos for a given plumage.
  ///
  /// Returns photo URLs from external sources (Macaulay Library, iNaturalist).
  /// Photos are not embedded in the database - this returns metadata only.
  Future<List<Photo>> getPhotosByPlumageId(int plumageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'plumage_id = ?',
      whereArgs: [plumageId],
    );
    return List.generate(maps.length, (i) => Photo.fromMap(maps[i]));
  }

  /// Gets a single photo by ID.
  ///
  /// Returns null if no photo with the given ID exists.
  Future<Photo?> getPhotoById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Photo.fromMap(maps.first);
  }

  // Region queries

  /// Gets all regions.
  ///
  /// Returns geographic regions (hierarchical) for filtering species by location.
  Future<List<Region>> getAllRegions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('regions');
    return List.generate(maps.length, (i) => Region.fromMap(maps[i]));
  }

  /// Gets a single region by ID.
  ///
  /// Returns null if no region with the given ID exists.
  Future<Region?> getRegionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'regions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Region.fromMap(maps.first);
  }

  /// Gets all child regions for a given parent region.
  ///
  /// For example, calling with California's ID returns all California sub-regions
  /// (Northern California, Central California, Southern California, etc.).
  Future<List<Region>> getChildRegions(int parentRegionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'regions',
      where: 'parent_region_id = ?',
      whereArgs: [parentRegionId],
    );
    return List.generate(maps.length, (i) => Region.fromMap(maps[i]));
  }

  // SpeciesRegion queries

  /// Gets all regions where a species occurs.
  ///
  /// Returns junction table records with occurrence frequency (common, uncommon, rare).
  Future<List<SpeciesRegion>> getSpeciesRegionsBySpeciesId(
      int speciesId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'species_regions',
      where: 'species_id = ?',
      whereArgs: [speciesId],
    );
    return List.generate(maps.length, (i) => SpeciesRegion.fromMap(maps[i]));
  }

  /// Gets all species that occur in a given region.
  ///
  /// Returns junction table records with occurrence frequency (common, uncommon, rare).
  Future<List<SpeciesRegion>> getSpeciesRegionsByRegionId(int regionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'species_regions',
      where: 'region_id = ?',
      whereArgs: [regionId],
    );
    return List.generate(maps.length, (i) => SpeciesRegion.fromMap(maps[i]));
  }

  /// Gets species for a region with occurrence levels.
  ///
  /// Returns species that occur in the given region along with their occurrence
  /// frequency (common, uncommon, rare). If [regionId] is null, returns all
  /// species with null occurrence.
  ///
  /// If [showOnlyCommon] is true, filters to only species with 'common' occurrence.
  Future<List<SpeciesWithOccurrence>> getSpeciesForRegion(
    int? regionId, {
    bool showOnlyCommon = false,
  }) async {
    final db = await database;

    // No region selected - return all species without occurrence info
    if (regionId == null) {
      final species = await getAllSpecies();
      return species
          .map((s) => SpeciesWithOccurrence(species: s, occurrence: null))
          .toList();
    }

    // Build query for species in the given region
    // Note: column is 'occurrence' in bundled DB (model expects this)
    String query = '''
      SELECT s.*, sr.occurrence as occurrence
      FROM species s
      INNER JOIN species_regions sr ON s.id = sr.species_id
      WHERE sr.region_id = ?
    ''';

    List<dynamic> args = [regionId];

    if (showOnlyCommon) {
      query += " AND sr.occurrence = 'common'";
    }

    query += ' ORDER BY s.taxonomic_order ASC, s.common_name ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    return maps.map((map) {
      return SpeciesWithOccurrence(
        species: Species.fromMap(map),
        occurrence: map['occurrence'] as String?,
      );
    }).toList();
  }

  /// Closes the database connection.
  ///
  /// Should be called when the app is shutting down. Generally not needed
  /// during normal operation.
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
