import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/region.dart';
import '../services/database_service.dart';

/// Settings screen for user preferences.
///
/// Allows users to configure:
/// - Region selection (for filtering species by location)
/// - Analytics opt-in (for crash reporting and usage stats)
/// - About information
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();

  List<Region> _regions = [];
  int? _selectedRegionId;
  bool _showOnlyCommon = false;
  bool _analyticsEnabled = false;
  bool _isLoading = true;

  // SharedPreferences keys
  static const String _keyRegionId = 'selected_region_id';
  static const String _keyShowOnlyCommon = 'show_only_common_species';
  static const String _keyAnalytics = 'analytics_enabled';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load regions from database
    final regions = await _db.getAllRegions();

    // Load saved preferences
    final prefs = await SharedPreferences.getInstance();
    final regionId = prefs.getInt(_keyRegionId);
    final showOnlyCommon = prefs.getBool(_keyShowOnlyCommon) ?? false;
    final analytics = prefs.getBool(_keyAnalytics) ?? false;

    setState(() {
      _regions = regions;
      _selectedRegionId = regionId;
      _showOnlyCommon = showOnlyCommon;
      _analyticsEnabled = analytics;
      _isLoading = false;
    });
  }

  Future<void> _saveRegion(int? regionId) async {
    final prefs = await SharedPreferences.getInstance();

    if (regionId == null) {
      await prefs.remove(_keyRegionId);
    } else {
      await prefs.setInt(_keyRegionId, regionId);
    }

    setState(() {
      _selectedRegionId = regionId;
    });
  }

  Future<void> _saveShowOnlyCommon(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowOnlyCommon, value);

    setState(() {
      _showOnlyCommon = value;
    });
  }

  Future<void> _saveAnalytics(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAnalytics, enabled);

    setState(() {
      _analyticsEnabled = enabled;
    });

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Analytics enabled - Thank you for helping improve LarID!'
                : 'Analytics disabled',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSection(
                  context,
                  title: 'Location',
                  children: [
                    _buildRegionSelector(),
                    const SizedBox(height: 16),
                    _buildShowOnlyCommonToggle(),
                  ],
                ),
                const Divider(),
                _buildSection(
                  context,
                  title: 'Privacy',
                  children: [
                    _buildAnalyticsToggle(),
                  ],
                ),
                const Divider(),
                _buildSection(
                  context,
                  title: 'About',
                  children: [
                    _buildAboutInfo(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your region to prioritize gulls common in your area',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Region',
            border: OutlineInputBorder(),
          ),
          initialValue: _selectedRegionId,
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('All regions'),
            ),
            ..._regions.map((region) {
              return DropdownMenuItem<int>(
                value: region.id,
                child: Text(region.name),
              );
            }),
          ],
          onChanged: _saveRegion,
        ),
      ],
    );
  }

  Widget _buildShowOnlyCommonToggle() {
    return SwitchListTile(
      title: const Text('Show only common species'),
      subtitle: Text(
        'Hide uncommon and rare species in results',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      value: _showOnlyCommon,
      onChanged: _saveShowOnlyCommon,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAnalyticsToggle() {
    return SwitchListTile(
      title: const Text('Enable analytics'),
      subtitle: Text(
        'Help improve LarID by sharing anonymous usage data and crash reports',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      value: _analyticsEnabled,
      onChanged: _saveAnalytics,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAboutInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.hasData
                ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                : '...';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Version'),
              subtitle: Text(version),
            );
          },
        ),
        // License
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('License'),
          subtitle: const Text('GPL-3.0 (Free & open source)'),
        ),
        // Source code
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Source Code'),
          subtitle: const Text('gitlab.com/colby.goettel/larid'),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () {
            // TODO: Open URL in browser (requires url_launcher package)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('gitlab.com/colby.goettel/larid'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        // Data sources
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Data Sources'),
          subtitle: const Text('Macaulay Library, iNaturalist, eBird'),
        ),
        // Support
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Support'),
          subtitle: const Text('Report issues on GitLab'),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () {
            // TODO: Open GitLab issues URL
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('gitlab.com/colby.goettel/larid/-/issues'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        // Contributors
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Contributors'),
          subtitle: const Text('Colby Goettel & Claude'),
        ),
        // Donate
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Buy me a coffee'),
          subtitle: const Text('Help cover hosting costs (always free, no ads)'),
          trailing: const Icon(Icons.coffee, size: 16),
          onTap: () {
            // TODO: Open URL in browser (requires url_launcher package)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('buymeacoffee.com/colby.goettel'),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Description
        Text(
          'LarID helps birders identify gulls through feature-based filtering. '
          'All data and photos are from openly licensed sources.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
