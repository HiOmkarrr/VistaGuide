import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage cache timestamps and expiration for AI-enhanced data
/// Implements 15-minute refresh strategy for optimal performance
class CacheManagerService {
  static final CacheManagerService _instance = CacheManagerService._internal();
  factory CacheManagerService() => _instance;
  CacheManagerService._internal();

  // Cache settings
  static const Duration _aiEnrichmentCacheExpiry = Duration(minutes: 2); // Reduced for testing/development

  // Cache keys
  static const String _aiEnrichmentPrefix = 'ai_enrichment_';
  static const String _destinationCachePrefix = 'destination_cache_';
  static const String _lastRecommendationsFetch = 'last_recommendations_fetch';
  static const String _cacheVersionKey = 'cache_version';
  static const int _currentCacheVersion = 1;

  SharedPreferences? _prefs;

  /// Initialize the cache manager
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _performCacheVersionCheck();
  }

  /// Check if cache version has changed and clear if needed
  Future<void> _performCacheVersionCheck() async {
    final currentVersion = _prefs?.getInt(_cacheVersionKey) ?? 0;
    if (currentVersion != _currentCacheVersion) {
      if (kDebugMode) {
        print('🧹 Cache version changed, clearing cache...');
      }
      await clearAllCache();
      await _prefs?.setInt(_cacheVersionKey, _currentCacheVersion);
    }

    // TEMPORARY: Clear AI cache for fresh development testing
    if (kDebugMode) {
      await clearAllAIEnrichmentCache();
      print('🧹 Cleared AI cache for fresh testing');
    }
  }

  /// Check if AI enrichment cache is expired for a destination
  bool isAIEnrichmentExpired(String destinationId) {
    final timestampString =
        _prefs?.getString('$_aiEnrichmentPrefix$destinationId');
    if (timestampString == null) return true;

    try {
      final timestamp = DateTime.parse(timestampString);
      final isExpired =
          DateTime.now().difference(timestamp) > _aiEnrichmentCacheExpiry;

      if (kDebugMode) {
        final minutesOld = DateTime.now().difference(timestamp).inMinutes;
        print(
            '🕐 AI cache for $destinationId: ${minutesOld}min old, expired: $isExpired');
      }

      return isExpired;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing AI cache timestamp for $destinationId: $e');
      }
      return true;
    }
  }

  /// Mark AI enrichment as fresh for a destination
  Future<void> markAIEnrichmentFresh(String destinationId) async {
    final timestamp = DateTime.now().toIso8601String();
    await _prefs?.setString('$_aiEnrichmentPrefix$destinationId', timestamp);

    if (kDebugMode) {
      print('✅ Marked AI enrichment fresh for $destinationId at $timestamp');
    }
  }

  /// Check if recommendations need to be refreshed (15-minute strategy)
  bool shouldRefreshRecommendations() {
    final timestampString = _prefs?.getString(_lastRecommendationsFetch);
    if (timestampString == null) return true;

    try {
      final timestamp = DateTime.parse(timestampString);
      final isExpired =
          DateTime.now().difference(timestamp) > _aiEnrichmentCacheExpiry;

      if (kDebugMode) {
        final minutesOld = DateTime.now().difference(timestamp).inMinutes;
        print(
            '🕐 Recommendations cache: ${minutesOld}min old, should refresh: $isExpired');
      }

      return isExpired;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing recommendations cache timestamp: $e');
      }
      return true;
    }
  }

  /// Mark recommendations as freshly fetched
  Future<void> markRecommendationsFresh() async {
    final timestamp = DateTime.now().toIso8601String();
    await _prefs?.setString(_lastRecommendationsFetch, timestamp);

    if (kDebugMode) {
      print('✅ Marked recommendations fresh at $timestamp');
    }
  }

  /// Get the age of AI enrichment for a destination in minutes
  int getAIEnrichmentAgeInMinutes(String destinationId) {
    final timestampString =
        _prefs?.getString('$_aiEnrichmentPrefix$destinationId');
    if (timestampString == null) return -1;

    try {
      final timestamp = DateTime.parse(timestampString);
      return DateTime.now().difference(timestamp).inMinutes;
    } catch (e) {
      return -1;
    }
  }

  /// Get the age of recommendations cache in minutes
  int getRecommendationsCacheAgeInMinutes() {
    final timestampString = _prefs?.getString(_lastRecommendationsFetch);
    if (timestampString == null) return -1;

    try {
      final timestamp = DateTime.parse(timestampString);
      return DateTime.now().difference(timestamp).inMinutes;
    } catch (e) {
      return -1;
    }
  }

  /// Clear AI enrichment cache for a specific destination
  Future<void> clearAIEnrichmentCache(String destinationId) async {
    await _prefs?.remove('$_aiEnrichmentPrefix$destinationId');

    if (kDebugMode) {
      print('🧹 Cleared AI enrichment cache for $destinationId');
    }
  }

  /// Clear all AI enrichment cache
  Future<void> clearAllAIEnrichmentCache() async {
    final keys = _prefs?.getKeys() ?? <String>{};
    final aiKeys = keys.where((key) => key.startsWith(_aiEnrichmentPrefix));

    for (final key in aiKeys) {
      await _prefs?.remove(key);
    }

    if (kDebugMode) {
      print('🧹 Cleared all AI enrichment cache (${aiKeys.length} entries)');
    }
  }

  /// Clear all cache data
  Future<void> clearAllCache() async {
    await _prefs?.clear();

    if (kDebugMode) {
      print('🧹 Cleared all cache data');
    }
  }

  /// Get cache statistics for monitoring
  Map<String, dynamic> getCacheStats() {
    final keys = _prefs?.getKeys() ?? <String>{};
    final aiCacheKeys =
        keys.where((key) => key.startsWith(_aiEnrichmentPrefix));
    final destinationCacheKeys =
        keys.where((key) => key.startsWith(_destinationCachePrefix));

    final recommendationsAge = getRecommendationsCacheAgeInMinutes();

    return {
      'aiEnrichmentEntries': aiCacheKeys.length,
      'destinationCacheEntries': destinationCacheKeys.length,
      'totalCacheEntries': keys.length,
      'recommendationsCacheAgeMinutes': recommendationsAge,
      'recommendationsCacheExpired':
          recommendationsAge > _aiEnrichmentCacheExpiry.inMinutes,
      'cacheVersion': _prefs?.getInt(_cacheVersionKey) ?? 0,
    };
  }

  /// Perform cache maintenance (cleanup expired entries)
  Future<void> performMaintenance() async {
    final keys = _prefs?.getKeys() ?? <String>{};
    int removedCount = 0;

    for (final key in keys) {
      if (key.startsWith(_aiEnrichmentPrefix)) {
        final destinationId = key.substring(_aiEnrichmentPrefix.length);
        if (isAIEnrichmentExpired(destinationId)) {
          await _prefs?.remove(key);
          removedCount++;
        }
      }
    }

    if (kDebugMode && removedCount > 0) {
      print('🧹 Cache maintenance: removed $removedCount expired entries');
    }
  }

  /// Store metadata about when destinations were cached
  Future<void> storeDestinationCacheMetadata(
      String destinationId, Map<String, dynamic> metadata) async {
    final metadataWithTimestamp = {
      ...metadata,
      'cachedAt': DateTime.now().toIso8601String(),
      'cacheVersion': _currentCacheVersion,
    };

    await _prefs?.setString(
      '$_destinationCachePrefix$destinationId',
      jsonEncode(metadataWithTimestamp),
    );
  }

  /// Get destination cache metadata
  Map<String, dynamic>? getDestinationCacheMetadata(String destinationId) {
    final metadataString =
        _prefs?.getString('$_destinationCachePrefix$destinationId');
    if (metadataString == null) return null;

    try {
      return jsonDecode(metadataString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ Error parsing destination cache metadata for $destinationId: $e');
      }
      return null;
    }
  }
}
