import 'package:flutter/material.dart';
import '../models/characteristic.dart';
import '../models/characteristic_value.dart';
import '../models/photo.dart';
import '../models/plumage.dart';
import '../models/species.dart';
import '../services/database_service.dart';
import '../widgets/photo_gallery.dart';

/// Detail screen showing full species and plumage information.
///
/// Displays comprehensive details about a specific gull plumage including
/// species info, characteristics, and photos.
class DetailScreen extends StatefulWidget {
  final int plumageId;

  const DetailScreen({
    super.key,
    required this.plumageId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final DatabaseService _db = DatabaseService();
  Plumage? _plumage;
  Species? _species;
  List<Photo> _photos = [];
  Map<Characteristic, CharacteristicValue> _characteristics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final plumage = await _db.getPlumageById(widget.plumageId);
    if (plumage != null) {
      final species = await _db.getSpeciesById(plumage.speciesId);
      final photos = await _db.getPhotosByPlumageId(plumage.id!);
      final characteristics = await _loadCharacteristics(plumage.id!);

      setState(() {
        _plumage = plumage;
        _species = species;
        _photos = photos;
        _characteristics = characteristics;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Loads all characteristics for a plumage with their values.
  Future<Map<Characteristic, CharacteristicValue>> _loadCharacteristics(
      int plumageId) async {
    final characteristics = <Characteristic, CharacteristicValue>{};
    final plumageChars =
        await _db.getPlumageCharacteristicsByPlumageId(plumageId);

    for (final pc in plumageChars) {
      final value =
          await _db.getCharacteristicValueById(pc.characteristicValueId);
      if (value != null) {
        final characteristic =
            await _db.getCharacteristicById(value.characteristicId);
        if (characteristic != null) {
          characteristics[characteristic] = value;
        }
      }
    }

    return characteristics;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_plumage == null || _species == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Plumage not found'),
        ),
      );
    }

    // Format plumage description (e.g., "first_year" -> "First year")
    String formatAgeClass(String ageClass) {
      return ageClass.split('_').map((word) {
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }

    String formatSeason(String? season) {
      if (season == null) return '';
      return season.split('_').map((word) {
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }

    final ageClassFormatted = formatAgeClass(_plumage!.ageClass);
    final seasonFormatted = _plumage!.season != null ? formatSeason(_plumage!.season) : null;
    final plumageDesc = seasonFormatted != null
        ? '$ageClassFormatted $seasonFormatted'
        : ageClassFormatted;

    return Scaffold(
      appBar: AppBar(
        title: Text(_species!.commonName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo gallery
            PhotoGallery(photos: _photos),
            const SizedBox(height: 16),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Species name
                  Text(
                    _species!.commonName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _species!.scientificName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Plumage type
                  _buildSectionHeader(context, 'Plumage'),
                  const SizedBox(height: 8),
                  Text(
                    plumageDesc,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  // Description
                  if (_plumage!.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _plumage!.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Characteristics
                  if (_characteristics.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Field Marks'),
                    const SizedBox(height: 12),
                    _buildCharacteristicsList(),
                  ] else ...[
                    _buildSectionHeader(context, 'Field Marks'),
                    const SizedBox(height: 12),
                    Text(
                      'No characteristics available for this plumage',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildCharacteristicsList() {
    // Sort characteristics by display order
    final sortedEntries = _characteristics.entries.toList()
      ..sort((a, b) =>
          (a.key.displayOrder ?? 999).compareTo(b.key.displayOrder ?? 999));

    return Column(
      children: sortedEntries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  entry.key.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value.displayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
