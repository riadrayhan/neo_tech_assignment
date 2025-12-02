import 'package:flutter/material.dart';
import '../models/chemical.dart';
import '../services/api_service.dart';

class ChemicalListScreen extends StatefulWidget {
  const ChemicalListScreen({super.key});

  @override
  State<ChemicalListScreen> createState() => _ChemicalListScreenState();
}

class _ChemicalListScreenState extends State<ChemicalListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Chemical>> _chemicalsFuture;

  @override
  void initState() {
    super.initState();
    _chemicalsFuture = _apiService.fetchChemicals();
  }

  void _refreshData() {
    setState(() {
      _chemicalsFuture = _apiService.fetchChemicals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chemical Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<Chemical>>(
        future: _chemicalsFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading chemicals...'),
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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Retry'),
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
              // Dashboard metrics
              _buildDashboard(chemicals.length),
              // Chemical list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _refreshData();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chemicals.length,
                    itemBuilder: (context, index) {
                      return _buildChemicalCard(chemicals[index]);
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

  Widget _buildDashboard(int totalChemicals) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
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
    );
  }

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
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildChemicalCard(Chemical chemical) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${chemical.currentStockQuantity} ${chemical.unit}',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.science, 'CAS: ${chemical.casNumber}'),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.business,
              'Manufacturer: ${chemical.manufacturerName}',
            ),
            if (chemical.category != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(Icons.category, 'Category: ${chemical.category}'),
            ],
            if (chemical.storageLocation != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.location_on,
                'Location: ${chemical.storageLocation}',
              ),
            ],
            if (chemical.expiryDate != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.calendar_today,
                'Expires: ${chemical.expiryDate}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
