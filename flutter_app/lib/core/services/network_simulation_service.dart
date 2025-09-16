import 'package:flutter/foundation.dart';

/// Network simulation service for testing offline behavior
/// Allows developers to simulate network conditions for testing
class NetworkSimulationService {
  static final NetworkSimulationService _instance =
      NetworkSimulationService._internal();
  factory NetworkSimulationService() => _instance;
  NetworkSimulationService._internal();

  // Simulation settings
  bool _simulateOffline = false;
  bool _simulateSlowNetwork = false;
  Duration _networkDelay = const Duration(milliseconds: 0);

  /// Enable airplane mode simulation (for testing offline behavior)
  void enableAirplaneMode() {
    _simulateOffline = true;
    if (kDebugMode) {
      print('✈️ AIRPLANE MODE SIMULATION ENABLED');
      print('   - All network calls will fail');
      print('   - App should use offline data only');
    }
  }

  /// Disable airplane mode simulation
  void disableAirplaneMode() {
    _simulateOffline = false;
    if (kDebugMode) {
      print('🌐 AIRPLANE MODE SIMULATION DISABLED');
      print('   - Network calls will work normally');
    }
  }

  /// Enable slow network simulation
  void enableSlowNetwork({Duration delay = const Duration(seconds: 3)}) {
    _simulateSlowNetwork = true;
    _networkDelay = delay;
    if (kDebugMode) {
      print('🐌 SLOW NETWORK SIMULATION ENABLED');
      print('   - Network calls will be delayed by ${delay.inSeconds}s');
    }
  }

  /// Disable slow network simulation
  void disableSlowNetwork() {
    _simulateSlowNetwork = false;
    _networkDelay = const Duration(milliseconds: 0);
    if (kDebugMode) {
      print('⚡ SLOW NETWORK SIMULATION DISABLED');
    }
  }

  /// Check if airplane mode is simulated
  bool get isAirplaneModeSimulated => _simulateOffline;

  /// Check if slow network is simulated
  bool get isSlowNetworkSimulated => _simulateSlowNetwork;

  /// Get the current network delay
  Duration get networkDelay => _networkDelay;

  /// Simulate network conditions (call this before any network operation)
  Future<bool> checkNetworkConditions() async {
    if (_simulateOffline) {
      if (kDebugMode) {
        print('✈️ SIMULATED: Network unavailable (airplane mode)');
      }
      return false;
    }

    if (_simulateSlowNetwork) {
      if (kDebugMode) {
        print(
            '🐌 SIMULATED: Slow network, waiting ${_networkDelay.inSeconds}s...');
      }
      await Future.delayed(_networkDelay);
    }

    return true;
  }

  /// Get current simulation status
  Map<String, dynamic> getSimulationStatus() {
    return {
      'airplaneMode': _simulateOffline,
      'slowNetwork': _simulateSlowNetwork,
      'networkDelay': _networkDelay.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset all simulations
  void resetSimulations() {
    _simulateOffline = false;
    _simulateSlowNetwork = false;
    _networkDelay = const Duration(milliseconds: 0);

    if (kDebugMode) {
      print('🔄 ALL NETWORK SIMULATIONS RESET');
    }
  }

  /// Quick test method to verify offline behavior
  Future<void> performOfflineTest() async {
    if (kDebugMode) {
      print('🧪 STARTING OFFLINE BEHAVIOR TEST...');

      // Enable airplane mode
      enableAirplaneMode();

      print('✈️ Step 1: Airplane mode enabled');
      print('📱 Step 2: App should now load from offline storage only');
      print('🚫 Step 3: No API calls should be made');
      print('⏱️ Step 4: Wait 10 seconds, then disable airplane mode...');

      await Future.delayed(const Duration(seconds: 10));

      disableAirplaneMode();

      print('✅ OFFLINE TEST COMPLETED');
      print('🔄 Network is now available again');
    }
  }

  /// Test slow network behavior
  Future<void> performSlowNetworkTest() async {
    if (kDebugMode) {
      print('🧪 STARTING SLOW NETWORK TEST...');

      enableSlowNetwork(delay: const Duration(seconds: 5));

      print('🐌 Network calls will now be 5 seconds slower');
      print('📱 App should prioritize offline data');

      await Future.delayed(const Duration(seconds: 15));

      disableSlowNetwork();

      print('✅ SLOW NETWORK TEST COMPLETED');
    }
  }
}
