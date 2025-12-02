import 'package:flutter/material.dart';
import '../models/chemical.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';

/// Screen displaying chemical inventory with offline support
///
/// Features:
/// - Displays list of chemicals from API
/// - Shows cached data when offline
/// - Pull to refresh functionality
/// - Animated list items
/// - Dashboard with metrics
class ChemicalListScreen extends StatefulWidget {
  const ChemicalListScreen({super.key});

  @override
  State<ChemicalListScreen> createState() => _ChemicalListScreenState();
}

class _ChemicalListScreenState extends State<ChemicalListScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService;
  final HiveService _hiveService;

  late Future<List<Chemical>> _chemicalsFuture;
  late AnimationController _listAnimationController;
  bool _isOffline = false;

  _ChemicalListScreenState()
      : _apiService = ApiService(),
        _hiveService = HiveService();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for list items
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Load chemicals
    _chemicalsFuture = _loadChemicals();

    // Start animation
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  /// Load chemicals with offline detection
  Future<List<Chemical>> _loadChemicals() async {
    try {
      final chemicals = await _apiService.fetchChemicals();
      setState(() => _isOffline = false);
      return chemicals;
    } catch (e) {
      // Check if we have cached data
      final cached = _hiveService.getCachedChemicals();
      if (cached != null) {
        setState(() => _isOffline = true);
        return cached;
      }
      rethrow;
    }
  }

  /// Refresh data from API
  void _refreshData() {
    setState(() {
      _chemicalsFuture = _loadChemicals();
    });
    _listAnimationController.reset();
    _listAnimationController.forward();
  }

  /// Show cache information dialog
  void _showCacheInfo() {
    final cacheInfo = _getCacheInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Has Cache', cacheInfo['has_cache'].toString()),
            _buildInfoRow('Cache Valid', cacheInfo['is_cache_valid'].toString()),
            _buildInfoRow('Pending Sync', cacheInfo['pending_sync_count'].toString()),
            if (cacheInfo['last_sync'] != null)
              _buildInfoRow(
                'Last Sync',
                _formatDateTime(DateTime.parse(cacheInfo['last_sync'])),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chemical Inventory'),
        actions: [
          // Show offline indicator
          if (_isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  'OFFLINE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.orange,
                padding: EdgeInsets.zero,
              ),
            ),
          // Cache info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showCacheInfo,
            tooltip: 'Cache Info',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Chemical>>(
        future: _chemicalsFuture,
        builder: (context, snapshot) {
          // Loading state with animated indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated circular progress indicator
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Pulsing text animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: const Text(
                          'Loading chemicals...',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    },
                    onEnd: () {
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated error icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chemicals found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by adding some chemicals to your inventory',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Success state with data
          final chemicals = snapshot.data!;

          return Column(
            children: [
              // Dashboard metrics with animations
              _buildAnimatedDashboard(chemicals.length),

              // Chemical list with staggered animations
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chemicals.length,
                    itemBuilder: (context, index) {
                      return _buildAnimatedChemicalCard(
                        chemicals[index],
                        index,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build animated dashboard with metrics
  Widget _buildAnimatedDashboard(int totalChemicals) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCard(
                    'Total Chemicals',
                    totalChemicals.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                  _buildMetricCard(
                    'Active SDS',
                    '12',
                    Icons.description,
                    Colors.green,
                  ),
                  _buildMetricCard(
                    'Incidents',
                    '2',
                    Icons.warning,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build metric card
  Widget _buildMetricCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  /// Build animated chemical card with staggered animation
  Widget _buildAnimatedChemicalCard(Chemical chemical, int index) {
    // Calculate staggered delay based on index
    final delay = index * 50;

    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        // Calculate progress with delay
        final progress = Curves.easeOut.transform(
          (_listAnimationController.value * 1000 - delay)
              .clamp(0.0, 1000.0) /
              1000,
        );

        return Transform.translate(
          offset: Offset(0, 50 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: child,
          ),
        );
      },
      child: _buildChemicalCard(chemical),
    );
  }

  /// Build chemical card
  Widget _buildChemicalCard(Chemical chemical) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Show detail dialog
          _showChemicalDetail(chemical);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chemical.productName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${chemical.currentStockQuantity} ${chemical.unit}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildChemicalInfoRow(Icons.science, 'CAS: ${chemical.casNumber}'),
              const SizedBox(height: 4),
              _buildChemicalInfoRow(
                Icons.business,
                'Manufacturer: ${chemical.manufacturerName}',
              ),
              if (chemical.category != null) ...[
                const SizedBox(height: 4),
                _buildChemicalInfoRow(
                  Icons.category,
                  'Category: ${chemical.category}',
                ),
              ],
              if (chemical.storageLocation != null) ...[
                const SizedBox(height: 4),
                _buildChemicalInfoRow(
                  Icons.location_on,
                  'Location: ${chemical.storageLocation}',
                ),
              ],
              if (chemical.expiryDate != null) ...[
                const SizedBox(height: 4),
                _buildChemicalInfoRow(
                  Icons.calendar_today,
                  'Expires: ${chemical.expiryDate}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build info row for chemical card
  Widget _buildChemicalInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Build info row for dialog
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// Show chemical detail dialog
  void _showChemicalDetail(Chemical chemical) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chemical.productName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('CAS Number', chemical.casNumber),
              _buildInfoRow('Manufacturer', chemical.manufacturerName),
              _buildInfoRow(
                'Stock',
                '${chemical.currentStockQuantity} ${chemical.unit}',
              ),
              if (chemical.category != null)
                _buildInfoRow('Category', chemical.category!),
              if (chemical.storageLocation != null)
                _buildInfoRow('Location', chemical.storageLocation!),
              if (chemical.expiryDate != null)
                _buildInfoRow('Expiry', chemical.expiryDate!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}