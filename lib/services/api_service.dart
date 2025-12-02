import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chemical.dart';
import '../models/api_response.dart';
import 'hive_service.dart';

class ApiService {
  static const String baseUrl =
      'https://api.jsonbin.io/v3/b/68918782f7e7a370d1f4029d';

  final HiveService _hiveService;

  ApiService() : _hiveService = HiveService();

  Future<List<Chemical>> fetchChemicals() async {
    try {
      // Attempt to fetch from API
      final response = await http.get(
        Uri.parse(baseUrl),
        // Set timeout to fail fast if offline
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Network timeout');
        },
      );

      if (response.statusCode == 200) {
        // Parse API response
        final jsonData = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonData);

        // Cache the response for offline access
        await _hiveService.cacheChemicals(apiResponse.chemicals);

        // Update last sync time
        await _hiveService.setLastSyncTime(DateTime.now());

        return apiResponse.chemicals;
      } else {
        throw Exception('Failed to load chemicals: ${response.statusCode}');
      }
    } catch (e) {
      // If API call fails, try to return cached data
      print('API error: $e - Attempting to load from cache');

      final cachedChemicals = _hiveService.getCachedChemicals();

      if (cachedChemicals != null && cachedChemicals.isNotEmpty) {
        // Return cached data if available
        return cachedChemicals;
      } else {
        // No cache available, throw error
        throw Exception('No internet connection and no cached data available');
      }
    }
  }

  /// Get chemicals with cache-first strategy
  /// Returns cached data immediately if valid, then updates in background
  Future<List<Chemical>> fetchChemicalsWithCache() async {
    // Check if we have valid cache
    if (_hiveService.isCacheValid()) {
      final cached = _hiveService.getCachedChemicals();
      if (cached != null && cached.isNotEmpty) {
        // Return cached data immediately
        // Optionally, update in background
        fetchChemicals().catchError((e) => print('Background update failed: $e'));
        return cached;
      }
    }

    // No valid cache, fetch from API
    return fetchChemicals();
  }

  /// Sync pending chemicals to server
  /// Used to upload data that was saved offline
  Future<bool> syncPendingChemicals() async {
    try {
      final pendingItems = _hiveService.getPendingSyncItems();

      if (pendingItems.isEmpty) {
        return true; // Nothing to sync
      }

      // In a real app, you would POST each item to the server
      // For now, we'll just simulate the sync
      for (final item in pendingItems) {
        // Simulate API call
        // await http.post(Uri.parse('$baseUrl/chemicals'), body: item);
        print('Syncing item: ${item['chemical']['product_name']}');
      }

      // Clear pending items after successful sync
      await _hiveService.clearPendingSync();

      return true;
    } catch (e) {
      print('Sync failed: $e');
      return false;
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}