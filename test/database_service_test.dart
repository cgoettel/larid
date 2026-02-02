import 'package:flutter_test/flutter_test.dart';
import 'package:larid/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for testing (required for desktop testing)
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Initialize sqflite for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService', () {
    late DatabaseService db;

    setUp(() {
      db = DatabaseService();
    });

    test('loads species from database', () async {
      final species = await db.getAllSpecies();

      // Should have 2 test species (Western Gull, California Gull)
      expect(species.length, 2);

      // Verify species are ordered correctly
      expect(species[0].commonName, 'Western Gull');
      expect(species[0].scientificName, 'Larus occidentalis');

      expect(species[1].commonName, 'California Gull');
      expect(species[1].scientificName, 'Larus californicus');
    });

    test('loads plumages for a species', () async {
      final species = await db.getAllSpecies();
      final westernGull = species.firstWhere((s) => s.commonName == 'Western Gull');

      final plumages = await db.getPlumagesBySpeciesId(westernGull.id!);

      // Should have at least 2 plumages (adult breeding, first-year)
      expect(plumages.length, greaterThanOrEqualTo(2));

      // Verify plumage data
      final adultBreeding = plumages.firstWhere(
        (p) => p.ageClass == 'adult' && p.season == 'breeding',
      );
      expect(adultBreeding.description, isNotNull);
    });

    test('loads characteristics', () async {
      final characteristics = await db.getAllCharacteristics();

      // Should have 5 test characteristics
      expect(characteristics.length, 5);

      // Verify display order
      expect(characteristics[0].displayOrder, lessThanOrEqualTo(characteristics[1].displayOrder!));
    });

    test('loads characteristic values for a characteristic', () async {
      final characteristics = await db.getAllCharacteristics();
      final legColor = characteristics.firstWhere((c) => c.name == 'leg_color');

      final values = await db.getCharacteristicValuesByCharacteristicId(legColor.id!);

      // Should have multiple leg color values
      expect(values.length, greaterThan(0));

      // Verify structure
      expect(values[0].value, isNotEmpty);
      expect(values[0].displayName, isNotEmpty);
    });

    test('loads plumage characteristics (junction table)', () async {
      final species = await db.getAllSpecies();
      final plumages = await db.getPlumagesBySpeciesId(species[0].id!);

      if (plumages.isNotEmpty) {
        final plumageChars = await db.getPlumageCharacteristicsByPlumageId(plumages[0].id!);

        // Each plumage should have characteristics
        expect(plumageChars.length, greaterThan(0));

        // Verify foreign keys are valid
        expect(plumageChars[0].plumageId, equals(plumages[0].id));
        expect(plumageChars[0].characteristicValueId, greaterThan(0));
      }
    });

    test('loads photos for a plumage', () async {
      final species = await db.getAllSpecies();
      final plumages = await db.getPlumagesBySpeciesId(species[0].id!);

      if (plumages.isNotEmpty) {
        final photos = await db.getPhotosByPlumageId(plumages[0].id!);

        // Each plumage should have at least one photo
        expect(photos.length, greaterThan(0));

        // Verify photo data structure
        expect(photos[0].url, isNotEmpty);
        expect(photos[0].license, isNotEmpty);
        expect(photos[0].source, isNotEmpty);
      }
    });

    test('loads regions', () async {
      final regions = await db.getAllRegions();

      // Should have 6 California regions in sample data
      expect(regions.length, 6);

      // Verify hierarchical structure
      final california = regions.firstWhere((r) => r.name == 'California');
      final childRegions = await db.getChildRegions(california.id!);

      // California should have child regions
      expect(childRegions.length, greaterThan(0));
    });

    test('loads species regions (junction table)', () async {
      final species = await db.getAllSpecies();
      final speciesRegions = await db.getSpeciesRegionsBySpeciesId(species[0].id!);

      // Species should occur in at least one region
      expect(speciesRegions.length, greaterThan(0));

      // Verify structure
      expect(speciesRegions[0].occurrence, isIn(['common', 'uncommon', 'rare']));
    });

    test('handles missing records gracefully', () async {
      final species = await db.getSpeciesById(9999);
      expect(species, isNull);

      final plumage = await db.getPlumageById(9999);
      expect(plumage, isNull);

      final photo = await db.getPhotoById(9999);
      expect(photo, isNull);
    });

    group('regional filtering', () {
      test('getSpeciesForRegion returns species with occurrence levels', () async {
        final regions = await db.getAllRegions();
        final california = regions.firstWhere((r) => r.name == 'California');

        final results = await db.getSpeciesForRegion(california.id!);

        // Should return species that occur in California
        expect(results.length, greaterThan(0));

        // Each result should have species and occurrence
        for (final result in results) {
          expect(result.species, isNotNull);
          expect(result.occurrence, isIn(['common', 'uncommon', 'rare']));
        }
      });

      test('getSpeciesForRegion with showOnlyCommon filters to common species', () async {
        final regions = await db.getAllRegions();
        final california = regions.firstWhere((r) => r.name == 'California');

        final allResults = await db.getSpeciesForRegion(california.id!);
        final commonOnly = await db.getSpeciesForRegion(
          california.id!,
          showOnlyCommon: true,
        );

        // Common-only results should be subset of all results
        expect(commonOnly.length, lessThanOrEqualTo(allResults.length));

        // All common-only results should have 'common' occurrence
        for (final result in commonOnly) {
          expect(result.occurrence, equals('common'));
        }
      });

      test('getSpeciesForRegion with null regionId returns all species', () async {
        final allSpecies = await db.getAllSpecies();
        final results = await db.getSpeciesForRegion(null);

        // Should return all species when no region filter
        expect(results.length, equals(allSpecies.length));

        // Occurrence should be null when no region context
        for (final result in results) {
          expect(result.occurrence, isNull);
        }
      });

      test('getSpeciesForRegion returns empty for region with no species', () async {
        // Region ID that doesn't exist or has no species
        final results = await db.getSpeciesForRegion(9999);
        expect(results, isEmpty);
      });
    });
  });
}
