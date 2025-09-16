import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cache_manager_service.dart';
import 'connectivity_service.dart';

/// Performance monitoring and cache management utilities
/// Provides insights into app performance and automated cache maintenance
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  final CacheManagerService _cacheManager = CacheManagerService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Performance metrics
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<int>> _operationDurations = {};
  Timer? _maintenanceTimer;

  /// Initialize the performance optimization service
  Future<void> initialize() async {
    await _cacheManager.initialize();
    _startAutomaticMaintenance();

    if (kDebugMode) {
      print('🎯 Performance optimization service initialized');
    }
  }

  /// Start timing an operation
  void startTiming(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// End timing an operation and record the duration
  void endTiming(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      _operationDurations[operationName] ??= [];
      _operationDurations[operationName]!.add(duration);

      // Keep only last 50 measurements to prevent memory growth
      if (_operationDurations[operationName]!.length > 50) {
        _operationDurations[operationName]!.removeAt(0);
      }

      _operationStartTimes.remove(operationName);

      if (kDebugMode) {
        print('⏱️ $operationName completed in ${duration}ms');
      }
    }
  }

  /// Get performance statistics for an operation
  Map<String, dynamic> getOperationStats(String operationName) {
    final durations = _operationDurations[operationName];
    if (durations == null || durations.isEmpty) {
      return {'error': 'No data available for $operationName'};
    }

    final sortedDurations = List<int>.from(durations)..sort();
    final count = durations.length;
    final sum = durations.reduce((a, b) => a + b);
    final average = sum / count;
    final median = count % 2 == 0
        ? (sortedDurations[count ~/ 2 - 1] + sortedDurations[count ~/ 2]) / 2
        : sortedDurations[count ~/ 2].toDouble();

    return {
      'operationName': operationName,
      'count': count,
      'averageMs': average.round(),
      'medianMs': median.round(),
      'minMs': sortedDurations.first,
      'maxMs': sortedDurations.last,
      'lastMs': durations.last,
    };
  }

  /// Get comprehensive performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'cacheStats': _cacheManager.getCacheStats(),
      'operationStats': {},
      'connectivity': {
        'lastCheck': _connectivityService.hasInternetConnectionCached(),
      },
    };

    // Add stats for each tracked operation
    for (final operationName in _operationDurations.keys) {
      report['operationStats'][operationName] =
          getOperationStats(operationName);
    }

    return report;
  }

  /// Start automatic cache maintenance (runs every 30 minutes)
  void _startAutomaticMaintenance() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _performMaintenanceTask();
    });

    if (kDebugMode) {
      print('🔧 Automatic maintenance scheduled every 30 minutes');
    }
  }

  /// Perform maintenance tasks
  Future<void> _performMaintenanceTask() async {
    try {
      if (kDebugMode) {
        print('🧹 Starting automatic maintenance...');
      }

      // Perform cache cleanup
      await _cacheManager.performMaintenance();

      // Clear old performance metrics (keep only recent data)
      _cleanupPerformanceMetrics();

      // Clear connectivity cache periodically
      _connectivityService.clearConnectivityCache();

      if (kDebugMode) {
        print('✅ Automatic maintenance completed');
        _printMaintenanceSummary();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Maintenance task failed: $e');
      }
    }
  }

  /// Clean up old performance metrics
  void _cleanupPerformanceMetrics() {
    int totalRemoved = 0;

    for (final operationName in _operationDurations.keys.toList()) {
      final durations = _operationDurations[operationName]!;
      if (durations.length > 30) {
        final removed = durations.length - 30;
        _operationDurations[operationName] = durations.sublist(removed);
        totalRemoved += removed;
      }
    }

    if (kDebugMode && totalRemoved > 0) {
      print('🧹 Cleaned up $totalRemoved old performance metrics');
    }
  }

  /// Print maintenance summary
  void _printMaintenanceSummary() {
    final report = getPerformanceReport();
    final cacheStats = report['cacheStats'] as Map<String, dynamic>;

    print('📊 Maintenance Summary:');
    print('   - AI cache entries: ${cacheStats['aiEnrichmentEntries']}');
    print('   - Total cache entries: ${cacheStats['totalCacheEntries']}');
    print(
        '   - Recommendations cache age: ${cacheStats['recommendationsCacheAgeMinutes']}min');
    print('   - Tracked operations: ${_operationDurations.keys.length}');
  }

  /// Force manual maintenance
  Future<void> performManualMaintenance() async {
    await _performMaintenanceTask();
  }

  /// Clear all performance data
  void clearPerformanceData() {
    _operationStartTimes.clear();
    _operationDurations.clear();

    if (kDebugMode) {
      print('🧹 Cleared all performance data');
    }
  }

  /// Check if the app should perform background optimization
  bool shouldPerformBackgroundOptimization() {
    // Perform optimization when:
    // 1. Has internet connection
    // 2. Cache has expired data
    // 3. Not during peak usage (avoid impacting user experience)

    final hasInternet = _connectivityService.hasInternetConnectionCached();
    if (hasInternet != true) return false;

    final cacheStats = _cacheManager.getCacheStats();
    final hasExpiredCache = cacheStats['recommendationsCacheExpired'] == true;

    return hasExpiredCache;
  }

  /// Get optimization recommendations
  List<String> getOptimizationRecommendations() {
    final recommendations = <String>[];
    final report = getPerformanceReport();
    final cacheStats = report['cacheStats'] as Map<String, dynamic>;

    // Check cache health
    final totalEntries = cacheStats['totalCacheEntries'] as int;
    if (totalEntries > 1000) {
      recommendations
          .add('Consider clearing old cache entries (${totalEntries} total)');
    }

    // Check AI cache age
    final aiEntries = cacheStats['aiEnrichmentEntries'] as int;
    if (aiEntries == 0) {
      recommendations
          .add('No AI-enhanced destinations cached - first load may be slower');
    }

    // Check performance metrics
    final operationStats = report['operationStats'] as Map<String, dynamic>;
    for (final entry in operationStats.entries) {
      final stats = entry.value as Map<String, dynamic>;
      final averageMs = stats['averageMs'] as int;

      if (averageMs > 5000) {
        // Operations taking more than 5 seconds
        recommendations.add('${entry.key} is slow (${averageMs}ms average)');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance is optimal');
    }

    return recommendations;
  }

  /// Dispose resources
  void dispose() {
    _maintenanceTimer?.cancel();
    _operationStartTimes.clear();
    _operationDurations.clear();

    if (kDebugMode) {
      print('🎯 Performance optimization service disposed');
    }
  }

  /// Get current app state for debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'activeTimers': _operationStartTimes.keys.toList(),
      'trackedOperations': _operationDurations.keys.toList(),
      'maintenanceActive': _maintenanceTimer?.isActive ?? false,
      'performanceReport': getPerformanceReport(),
      'optimizationRecommendations': getOptimizationRecommendations(),
    };
  }
}
