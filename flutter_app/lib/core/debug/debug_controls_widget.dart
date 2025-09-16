import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/network_simulation_service.dart';
import '../services/cache_manager_service.dart';
import '../services/connectivity_service.dart';
import '../services/performance_optimization_service.dart';

/// Debug utility widget for testing offline behavior and performance
/// Only available in debug mode
class DebugControlsWidget extends StatefulWidget {
  const DebugControlsWidget({super.key});

  @override
  State<DebugControlsWidget> createState() => _DebugControlsWidgetState();
}

class _DebugControlsWidgetState extends State<DebugControlsWidget> {
  final NetworkSimulationService _networkSim = NetworkSimulationService();
  final CacheManagerService _cacheManager = CacheManagerService();
  final ConnectivityService _connectivity = ConnectivityService();
  final PerformanceOptimizationService _performance =
      PerformanceOptimizationService();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink(); // Hide in release mode
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Controls'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildNetworkSimulationSection(),
            const SizedBox(height: 20),
            _buildCacheManagementSection(),
            const SizedBox(height: 20),
            _buildPerformanceSection(),
            const SizedBox(height: 20),
            _buildTestingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSimulationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌐 Network Simulation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                _networkSim.enableAirplaneMode();
                _showMessage(
                    '✈️ Airplane mode enabled - App should use offline data only');
              },
              icon: const Icon(Icons.airplanemode_active),
              label: const Text('Enable Airplane Mode'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                _networkSim.disableAirplaneMode();
                _showMessage(
                    '🌐 Airplane mode disabled - Network calls allowed');
              },
              icon: const Icon(Icons.wifi),
              label: const Text('Disable Airplane Mode'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                _networkSim.enableSlowNetwork();
                _showMessage('🐌 Slow network enabled - 3 second delays');
              },
              icon: const Icon(Icons.network_check),
              label: const Text('Enable Slow Network'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📱 Cache Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final stats = _cacheManager.getCacheStats();
                _showCacheStats(stats);
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Show Cache Stats'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await _cacheManager.clearAllAIEnrichmentCache();
                _showMessage(
                    '🧹 AI cache cleared - Next loads will trigger fresh AI enhancement');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear AI Cache'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await _cacheManager.performMaintenance();
                _showMessage('🧹 Cache maintenance completed');
              },
              icon: const Icon(Icons.build),
              label: const Text('Run Maintenance'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⏱️ Performance Monitoring',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final report = _performance.getPerformanceReport();
                _showPerformanceReport(report);
              },
              icon: const Icon(Icons.speed),
              label: const Text('Performance Report'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final recommendations =
                    _performance.getOptimizationRecommendations();
                _showOptimizationRecommendations(recommendations);
              },
              icon: const Icon(Icons.lightbulb),
              label: const Text('Optimization Tips'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Automated Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                _showMessage('🧪 Starting offline test...');
                await _networkSim.performOfflineTest();
                _showMessage('✅ Offline test completed');
              },
              icon: const Icon(Icons.science),
              label: const Text('Run Offline Test'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                _showMessage('🧪 Starting slow network test...');
                await _networkSim.performSlowNetworkTest();
                _showMessage('✅ Slow network test completed');
              },
              icon: const Icon(Icons.network_check),
              label: const Text('Run Slow Network Test'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final hasInternet = await _connectivity.hasInternetConnection();
                _showMessage(
                    '🌐 Connectivity check: ${hasInternet ? "Connected" : "Offline"}');
              },
              icon: const Icon(Icons.wifi_find),
              label: const Text('Test Connectivity'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );

    if (kDebugMode) {
      print('🛠️ DEBUG: $message');
    }
  }

  void _showCacheStats(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Cache Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('AI Enrichment Entries: ${stats['aiEnrichmentEntries']}'),
              Text('Total Cache Entries: ${stats['totalCacheEntries']}'),
              Text(
                  'Recommendations Cache Age: ${stats['recommendationsCacheAgeMinutes']}min'),
              Text('Cache Expired: ${stats['recommendationsCacheExpired']}'),
              Text('Cache Version: ${stats['cacheVersion']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPerformanceReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏱️ Performance Report'),
        content: SingleChildScrollView(
          child: Text(
            'Performance data would be displayed here.\n'
            'Check console for detailed logs.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOptimizationRecommendations(List<String> recommendations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Optimization Recommendations'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: recommendations
                .map((rec) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $rec'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
