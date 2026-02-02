import 'package:flutter/material.dart';
import '../providers/filter_provider.dart';
import 'species_card.dart';

/// List widget displaying filtered gull identification results.
///
/// Shows a scrollable list of species/plumage cards matching the current
/// filter criteria. Handles empty state when no results match.
class ResultsList extends StatelessWidget {
  final List<PlumageResult> results;
  final Function(PlumageResult) onResultTap;

  const ResultsList({
    super.key,
    required this.results,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return SpeciesCard(
          result: result,
          onTap: () => onResultTap(result),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters to see more results',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
