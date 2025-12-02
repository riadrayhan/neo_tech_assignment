import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/api_service.dart';

/// Settings screen for app configuration
///
/// Features:
/// - Dark mode toggle
/// - Cache management
/// - Sync status
/// - About information
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HiveService _hiveService = HiveService();
  final ApiService _apiService = ApiService();

  bool _isSyncing = false;
  String _syncStatus = 'Not synced';

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  /// Load sync status from cache
  void _loadSyncStatus() {
    final lastSync = _hiveService.getLastSyncTime();
    if (lastSync != null) {
      setState(() {
        _syncStatus = 'Last synced: ${_formatDateTime(lastSync)}';
      });
    }
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Sync pending data
  Future<void> _syncData() async {
    setState(() => _isSyncing = true);

    try {
      final success = await _apiService.syncPendingChemicals();

      if (success) {
        _showSnackBar('Data synced successfully', Colors.green);
        _loadSyncStatus();
      } else {
        _showSnackBar('Sync failed', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  /// Clear all cached data
  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear all cached data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _hiveService.clearAllCache();
      _showSnackBar('Cache cleared', Colors.green);
      setState(() {
        _syncStatus = 'Not synced';
      });
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  /// Show about dialog
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Chemical Inventory',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.science, size: 48),
      children: [
        const Text(
          'A comprehensive chemical inventory management system with offline support.',
        ),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Offline caching with Hive'),
        const Text('• Dark mode support'),
        const Text('• OCR text recognition'),
        const Text('• Manual data entry'),
      ],
    );
  }

  /// Get cache information
  Map<String, dynamic> _getCacheInfo() {
    final timestamp = _hiveService.getCacheTimestamp();
    final isValid = _hiveService.isCacheValid();
    final lastSync = _hiveService.getLastSyncTime();
    final pendingCount = _hiveService.getPendingSyncCount();

    return {
      'has_cache': timestamp != null,
      'cache_timestamp': timestamp?.toIso8601String(),
      'is_cache_valid': isValid,
      'last_sync': lastSync?.toIso8601String(),
      'pending_sync_count': pendingCount,
    };
  }

  /// Toggle theme and show restart dialog
  void _toggleTheme(bool value) {
    _hiveService.setDarkMode(value);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Changed'),
        content: const Text(
          'Please restart the app to apply the new theme.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _hiveService.getDarkMode();
    final cacheInfo = _getCacheInfo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Section
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark theme'),
            value: isDarkMode,
            onChanged: _toggleTheme,
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
          const Divider(),

          // Data & Sync Section
          _buildSectionHeader('Data & Sync'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Data'),
            subtitle: Text(_syncStatus),
            trailing: _isSyncing
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.chevron_right),
            onTap: _isSyncing ? null : _syncData,
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions),
            title: const Text('Pending Sync Items'),
            subtitle: Text('${cacheInfo['pending_sync_count']} items'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),

          // Cache Section
          _buildSectionHeader('Cache'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Cache Status'),
            subtitle: Text(
              cacheInfo['has_cache']
                  ? 'Cache available${cacheInfo['is_cache_valid'] ? ' (valid)' : ' (stale)'}'
                  : 'No cache',
            ),
            trailing: const Icon(Icons.info_outline),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Clear Cache'),
            subtitle: const Text('Remove all cached data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearCache,
          ),
          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAbout,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showSnackBar('Privacy policy not available', Colors.grey);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showSnackBar('Terms not available', Colors.grey);
            },
          ),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}