import 'package:flutter/material.dart';
import '../providers/filter_provider.dart';

/// Card widget displaying a species/plumage result item.
///
/// Shows species name, plumage type (age class + season), and handles
/// tap navigation to the detail screen.
class SpeciesCard extends StatelessWidget {
  final PlumageResult result;
  final VoidCallback onTap;

  const SpeciesCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plumage = result.plumage;
    final species = result.species;

    // Build plumage description (e.g., "Adult breeding")
    final plumageDesc = plumage.season != null
        ? '${plumage.ageClass} ${plumage.season}'
        : plumage.ageClass;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Placeholder for future thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              // Species and plumage info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            species.commonName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (result.occurrence != null &&
                            result.occurrence != 'common')
                          _buildOccurrenceChip(theme, result.occurrence!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plumageDesc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      species.scientificName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccurrenceChip(ThemeData theme, String occurrence) {
    final isRare = occurrence == 'rare';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isRare
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        occurrence,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isRare
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
