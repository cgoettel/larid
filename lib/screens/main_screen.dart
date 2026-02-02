import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/filter_controls.dart';
import '../widgets/results_list.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

/// Main screen for the LarID app.
///
/// Displays filter controls at the top and a scrollable list of results below.
/// Implements the primary identification workflow: filter by characteristics
/// to find matching gull species/plumages.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LarID'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              // Refresh region settings when returning from settings
              if (context.mounted) {
                context.read<FilterProvider>().refreshRegionSettings();
              }
            },
          ),
        ],
      ),
      body: Consumer<FilterProvider>(
        builder: (context, filterProvider, child) {
          if (filterProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Filter controls
              const FilterControls(),
              // Results list
              Expanded(
                child: ResultsList(
                  results: filterProvider.results,
                  onResultTap: (result) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          plumageId: result.plumage.id!,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
