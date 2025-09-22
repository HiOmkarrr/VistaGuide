import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'network_simulation_service.dart';

/// Service to check internet connectivity and network status
/// Used to determine when AI enrichment should be performed
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final NetworkSimulationService _networkSimulation =
      NetworkSimulationService();

  // Cache connectivity status to avoid repeated checks
  bool? _lastConnectivityStatus;
  DateTime? _lastConnectivityCheck;
  static const Duration _connectivityCacheTimeout = Duration(seconds: 30);

  /// Check if device has internet connectivity
  /// Returns cached result if checked within 30 seconds
  /// Respects network simulation settings for testing
  Future<bool> hasInternetConnection() async {
    try {
      // Check network simulation first (for testing offline behavior)
      if (_networkSimulation.isAirplaneModeSimulated) {
        if (kDebugMode) {
          print('✈️ SIMULATED OFFLINE MODE - Returning false');
        }
        _lastConnectivityStatus = false;
        _lastConnectivityCheck = DateTime.now();
        return false;
      }

      // Return cached result if recent
      if (_lastConnectivityCheck != null &&
          _lastConnectivityStatus != null &&
          DateTime.now().difference(_lastConnectivityCheck!) <
              _connectivityCacheTimeout) {
        if (kDebugMode) {
          print('📱 USING CACHED CONNECTIVITY: $_lastConnectivityStatus');
        }
        return _lastConnectivityStatus!;
      }

      // Perform actual connectivity check
      if (kDebugMode) {
        print('🌐 CHECKING INTERNET CONNECTIVITY...');
      }

      // Apply network simulation delay if enabled
      if (_networkSimulation.isSlowNetworkSimulated) {
        if (kDebugMode) {
          print('🐌 SIMULATING SLOW NETWORK...');
        }
        await Future.delayed(_networkSimulation.networkDelay);
      }

      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 2), // Reduced from 5 to 2 seconds for faster offline detection
      );

      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      // Cache the result
      _lastConnectivityStatus = isConnected;
      _lastConnectivityCheck = DateTime.now();

      if (kDebugMode) {
        print(isConnected
            ? '✅ INTERNET CONNECTION AVAILABLE'
            : '❌ NO INTERNET CONNECTION');
      }

      return isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('❌ INTERNET CONNECTIVITY CHECK FAILED: $e');
      }

      // Cache negative result
      _lastConnectivityStatus = false;
      _lastConnectivityCheck = DateTime.now();

      return false;
    }
  }

  /// Check if device has internet connectivity (synchronous with cached result)
  /// Returns null if no cached result available
  bool? hasInternetConnectionCached() {
    if (_lastConnectivityCheck != null &&
        _lastConnectivityStatus != null &&
        DateTime.now().difference(_lastConnectivityCheck!) <
            _connectivityCacheTimeout) {
      return _lastConnectivityStatus;
    }
    return null;
  }

  /// Clear connectivity cache (force next check to be fresh)
  void clearConnectivityCache() {
    _lastConnectivityStatus = null;
    _lastConnectivityCheck = null;
  }

  /// Check if network is available for AI operations
  /// More lenient check that considers mobile data and wifi
  Future<bool> isNetworkAvailableForAI() async {
    try {
      // For AI operations, we want to be more conservative
      // Check multiple endpoints for reliability
      final futures = [
        InternetAddress.lookup('google.com'),
        InternetAddress.lookup('api.gemini.google.com'),
      ];

      final results = await Future.wait(
        futures.map((future) => future.timeout(const Duration(seconds: 3))),
        eagerError: false,
      );

      // Consider network available if at least one lookup succeeds
      for (final result in results) {
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('🌐 Network check for AI failed: $e');
      }
      return false;
    }
  }
}
