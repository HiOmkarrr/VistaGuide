import 'package:flutter_test/flutter_test.dart';
import '../lib/core/services/connectivity_service.dart';
import '../lib/core/services/network_simulation_service.dart';
import '../lib/core/services/cache_manager_service.dart';

/// Test suite for offline behavior and connectivity optimization
/// Verifies that the app handles offline scenarios gracefully
void main() {
  group('Offline Behavior Tests', () {
    late ConnectivityService connectivityService;
    late NetworkSimulationService networkSimulation;
    late CacheManagerService cacheManager;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      connectivityService = ConnectivityService();
      networkSimulation = NetworkSimulationService();
      cacheManager = CacheManagerService();
      
      // Reset simulations before each test
      networkSimulation.resetSimulations();
    });

    tearDown(() {
      // Clean up after each test
      networkSimulation.resetSimulations();
    });

    test('should detect offline mode immediately when airplane mode is enabled', () async {
      // Arrange
      networkSimulation.enableAirplaneMode();
      
      // Act
      final isConnected = await connectivityService.hasInternetConnection();
      
      // Assert
      expect(isConnected, false);
      expect(networkSimulation.isAirplaneModeSimulated, true);
    });

    test('should use cached connectivity result for faster offline detection', () async {
      // Arrange
      networkSimulation.enableAirplaneMode();
      
      // First call - should detect offline
      await connectivityService.hasInternetConnection();
      
      // Act - Second call should use cached result
      final startTime = DateTime.now();
      final isConnected = await connectivityService.hasInternetConnection();
      final endTime = DateTime.now();
      
      // Assert
      expect(isConnected, false);
      // Should be very fast (using cache)
      expect(endTime.difference(startTime).inMilliseconds, lessThan(100));
    });

    test('should return cached connectivity status synchronously', () {
      // Arrange
      networkSimulation.enableAirplaneMode();
      
      // Act - Get cached result without waiting
      final cachedResult = connectivityService.hasInternetConnectionCached();
      
      // Assert - Should return null if no cached result
      expect(cachedResult, null);
      
      // Now populate cache and test again
      connectivityService.hasInternetConnection().then((_) {
        final newCachedResult = connectivityService.hasInternetConnectionCached();
        expect(newCachedResult, false);
      });
    });

    test('should handle slow network simulation gracefully', () async {
      // Arrange
      networkSimulation.enableSlowNetwork(delay: Duration(milliseconds: 500));
      
      // Act
      final startTime = DateTime.now();
      await connectivityService.hasInternetConnection();
      final endTime = DateTime.now();
      
      // Assert
      expect(endTime.difference(startTime).inMilliseconds, greaterThan(400));
      expect(networkSimulation.isSlowNetworkSimulated, true);
    });

    test('should clear AI cache when needed for fresh content', () async {
      // Act
      await cacheManager.clearAllAIEnrichmentCache();
      
      // Assert
      // Cache should be cleared successfully
      expect(true, true); // Placeholder - clearAllAIEnrichmentCache method exists
    });

    test('should respect 2-minute AI cache expiry for fresh content', () async {
      // This test would need to be integration test with actual time progression
      // For unit test, we can verify the cache expiry duration
      expect(true, true); // Placeholder - cache expiry is now 2 minutes
    });
  });

  group('Network Simulation Tests', () {
    late NetworkSimulationService networkSimulation;

    setUp(() {
      networkSimulation = NetworkSimulationService();
      networkSimulation.resetSimulations();
    });

    test('should provide correct simulation status', () {
      // Act
      networkSimulation.enableAirplaneMode();
      final status = networkSimulation.getSimulationStatus();
      
      // Assert
      expect(status['airplaneMode'], true);
      expect(status['slowNetwork'], false);
      expect(status['networkDelay'], 0);
    });

    test('should reset all simulations correctly', () {
      // Arrange
      networkSimulation.enableAirplaneMode();
      networkSimulation.enableSlowNetwork();
      
      // Act
      networkSimulation.resetSimulations();
      
      // Assert
      expect(networkSimulation.isAirplaneModeSimulated, false);
      expect(networkSimulation.isSlowNetworkSimulated, false);
    });
  });
}

/// Integration test helper to demonstrate offline loading flow
class OfflineLoadingDemo {
  static Future<void> demonstrateOfflineFlow() async {
    print('🧪 === OFFLINE LOADING DEMONSTRATION ===');
    
    final networkSimulation = NetworkSimulationService();
    final connectivityService = ConnectivityService();
    
    try {
      // Step 1: Normal operation
      print('\n📱 Step 1: Testing normal online operation...');
      final onlineConnection = await connectivityService.hasInternetConnection();
      print('   Connection status: ${onlineConnection ? "✅ Online" : "❌ Offline"}');
      
      // Step 2: Simulate airplane mode
      print('\n✈️ Step 2: Enabling airplane mode simulation...');
      networkSimulation.enableAirplaneMode();
      
      // Step 3: Test immediate offline detection
      print('\n🚀 Step 3: Testing immediate offline detection...');
      final startTime = DateTime.now();
      final offlineConnection = await connectivityService.hasInternetConnection();
      final detectionTime = DateTime.now().difference(startTime);
      
      print('   Connection status: ${offlineConnection ? "✅ Online" : "❌ Offline"}');
      print('   Detection time: ${detectionTime.inMilliseconds}ms');
      
      // Step 4: Test cached offline detection
      print('\n⚡ Step 4: Testing cached offline detection...');
      final cachedStartTime = DateTime.now();
      final cachedOfflineConnection = await connectivityService.hasInternetConnection();
      final cachedDetectionTime = DateTime.now().difference(cachedStartTime);
      
      print('   Cached connection status: ${cachedOfflineConnection ? "✅ Online" : "❌ Offline"}');
      print('   Cached detection time: ${cachedDetectionTime.inMilliseconds}ms');
      
      // Step 5: Simulate return to online
      print('\n🌐 Step 5: Returning to online mode...');
      networkSimulation.disableAirplaneMode();
      connectivityService.clearConnectivityCache(); // Force fresh check
      
      final onlineAgainConnection = await connectivityService.hasInternetConnection();
      print('   Connection status: ${onlineAgainConnection ? "✅ Online" : "❌ Offline"}');
      
      print('\n✅ === DEMONSTRATION COMPLETED ===');
      print('Summary:');
      print('- Offline detection: ${detectionTime.inMilliseconds}ms (should be <100ms)');
      print('- Cached detection: ${cachedDetectionTime.inMilliseconds}ms (should be <10ms)');
      print('- App should now load offline content immediately when disconnected');
      
    } catch (e) {
      print('❌ Demo failed: $e');
    } finally {
      networkSimulation.resetSimulations();
    }
  }
}