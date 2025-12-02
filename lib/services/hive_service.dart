import 'package:hive_flutter/hive_flutter.dart';
import '../models/chemical.dart';


class HiveService {
  // Singleton pattern
  static final HiveService _instance = HiveService._internal();

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  // Box names for different data types
  static const String _chemicalsBox = 'chemicals';
  static const String _pendingSyncBox = 'pending_sync';
  static const String _settingsBox = 'settings';

  /// Initialize Hive database
  /// Must be called before any other Hive operations
  static Future<void> initialize() async {
    // Initialize Hive with Flutter support
    await Hive.initFlutter();

    // Register custom adapters if needed
    // Hive.registerAdapter(ChemicalAdapter());

    // Open boxes for different data types
    await Hive.openBox(_chemicalsBox);
    await Hive.openBox(_pendingSyncBox);
    await Hive.openBox(_settingsBox);
  }

  /// Get the chemicals box
  Box get _chemicals => Hive.box(_chemicalsBox);

  /// Get the pending sync box
  Box get _pendingSync => Hive.box(_pendingSyncBox);

  /// Get the settings box
  Box get _settings => Hive.box(_settingsBox);

  // ==================== Chemical Management ====================

  /// Cache chemicals from API response
  /// This allows offline access to previously fetched data
  Future<void> cacheChemicals(List<Chemical> chemicals) async {
    try {
      // Convert chemicals to JSON format for storage
      final chemicalsJson = chemicals.map((c) => c.toJson()).toList();

      // Store with timestamp for cache invalidation
      await _chemicals.put('cached_chemicals', {
        'data': chemicalsJson,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error caching chemicals: $e');
    }
  }

  /// Retrieve cached chemicals from local storage
  /// Returns null if no cache exists
  List<Chemical>? getCachedChemicals() {
    try {
      final cached = _chemicals.get('cached_chemicals');

      if (cached == null) return null;

      final List<dynamic> chemicalsJson = cached['data'];
      return chemicalsJson
          .map((json) => Chemical.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error retrieving cached chemicals: $e');
      return null;
    }
  }

  /// Get cache timestamp to check if data is stale
  DateTime? getCacheTimestamp() {
    try {
      final cached = _chemicals.get('cached_chemicals');
      if (cached == null) return null;

      return DateTime.parse(cached['timestamp']);
    } catch (e) {
      return null;
    }
  }

  /// Check if cache is valid (less than 24 hours old)
  bool isCacheValid() {
    final timestamp = getCacheTimestamp();
    if (timestamp == null) return false;

    final difference = DateTime.now().difference(timestamp);
    return difference.inHours < 24;
  }

  // ==================== Pending Sync Management ====================

  /// Add a chemical to pending sync queue
  /// Used when adding data offline that needs to be synced later
  Future<void> addPendingSync(Chemical chemical) async {
    try {
      final pendingList = _pendingSync.get('pending_items', defaultValue: []);
      pendingList.add({
        'chemical': chemical.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _pendingSync.put('pending_items', pendingList);
    } catch (e) {
      print('Error adding to pending sync: $e');
    }
  }

  /// Get all items pending synchronization
  List<Map<String, dynamic>> getPendingSyncItems() {
    try {
      final items = _pendingSync.get('pending_items', defaultValue: []);
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      print('Error getting pending sync items: $e');
      return [];
    }
  }

  /// Clear pending sync queue after successful synchronization
  Future<void> clearPendingSync() async {
    await _pendingSync.put('pending_items', []);
  }

  /// Get count of pending items
  int getPendingSyncCount() {
    return getPendingSyncItems().length;
  }

  // ==================== Settings Management ====================

  /// Save dark mode preference
  Future<void> setDarkMode(bool isDark) async {
    await _settings.put('dark_mode', isDark);
  }

  /// Get dark mode preference
  bool getDarkMode() {
    return _settings.get('dark_mode', defaultValue: false);
  }

  /// Save last sync timestamp
  Future<void> setLastSyncTime(DateTime time) async {
    await _settings.put('last_sync', time.toIso8601String());
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    try {
      final timeStr = _settings.get('last_sync');
      return timeStr != null ? DateTime.parse(timeStr) : null;
    } catch (e) {
      return null;
    }
  }

  // ==================== Cleanup ====================

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _chemicals.clear();
    await _pendingSync.clear();
  }

  /// Close all Hive boxes
  /// Should be called when app is closing
  Future<void> close() async {
    await Hive.close();
  }
}