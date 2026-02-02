import 'species.dart';

/// Species with its occurrence level in a specific region.
///
/// Used when querying species filtered by region to include
/// the occurrence frequency (common, uncommon, rare) for display.
class SpeciesWithOccurrence {
  final Species species;

  /// Occurrence level in the selected region (common, uncommon, rare).
  /// Null when no region is selected (showing all species).
  final String? occurrence;

  SpeciesWithOccurrence({
    required this.species,
    this.occurrence,
  });
}
