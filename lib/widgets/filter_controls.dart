import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';

/// Maps characteristic value names to colors for visual indicators.
/// TODO: Replace with custom illustrations (Issue #15)
final Map<String, Color> _characteristicColors = {
  // Leg colors
  'pink': Colors.pink.shade300,
  'yellow': Colors.yellow.shade700,
  'gray': Colors.grey.shade600,
  'greenish': Colors.green.shade400,
  'black': Colors.black,
  'red': Colors.red.shade600,
  'orange': Colors.orange.shade600,

  // Bill colors
  'yellow_bill': Colors.yellow.shade700,
  'red_bill': Colors.red.shade600,
  'black_bill': Colors.black,
  'orange_bill': Colors.orange.shade600,

  // Mantle/back colors
  'dark_gray': Colors.grey.shade800,
  'light_gray': Colors.grey.shade400,
  'black_mantle': Colors.black,
  'slate': Colors.blueGrey.shade700,

  // Head colors
  'white': Colors.white,
  'streaked': Colors.grey.shade300,
  'brown': Colors.brown.shade400,
};

/// Gets color for a characteristic value, with fallback.
Color? _getColorForValue(String valueName) {
  final normalized = valueName.toLowerCase().replaceAll(' ', '_');
  return _characteristicColors[normalized];
}

/// Widget providing filter controls for characteristic selection.
///
/// Displays dropdown selectors for each characteristic (leg color, bill pattern, etc.)
/// and updates the FilterProvider when selections change.
class FilterControls extends StatelessWidget {
  const FilterControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        final characteristics = filterProvider.characteristics;

        if (characteristics.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active filter count and clear button
            if (filterProvider.hasActiveFilters) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '${filterProvider.selectedValues.length} filter(s) active',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => filterProvider.clearFilters(),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            // Filter dropdowns
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: characteristics.map((characteristic) {
                  return _buildFilterDropdown(
                    context,
                    filterProvider,
                    characteristic,
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context,
    FilterProvider filterProvider,
    characteristic,
  ) {
    final values = filterProvider.characteristicValues[characteristic.id] ?? [];
    final selectedValueIds =
        filterProvider.selectedValues[characteristic.id] ?? {};
    final selectedValueId =
        selectedValueIds.isNotEmpty ? selectedValueIds.first : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 300),
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: characteristic.displayName,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        initialValue: selectedValueId,
        items: [
          const DropdownMenuItem<int>(
            value: null,
            child: Text('Any'),
          ),
          ...values.map((value) {
            final color = _getColorForValue(value.value);
            return DropdownMenuItem<int>(
              value: value.id,
              child: Row(
                children: [
                  if (color != null) ...[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      value.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: (valueId) {
          filterProvider.updateFilter(characteristic.id!, valueId);
        },
        isExpanded: true,
      ),
    );
  }
}
