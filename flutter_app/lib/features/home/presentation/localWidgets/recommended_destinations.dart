import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/firestore_travel_service.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/models/destination.dart';
import 'destination_card.dart';

/// Enhanced recommended destinations section widget with dynamic loading and offline support
class RecommendedDestinations extends StatefulWidget {
  final Function(String destinationId, Destination destination)?
      onDestinationTap;
  final Function(Destination destination)? onLandmarkDetected;
  final String sectionTitle;
  final int limit;
  final List<String>? preferredTypes;
  final bool enableLocationBasedRecommendations;

  const RecommendedDestinations({
    super.key,
    this.onDestinationTap,
    this.onLandmarkDetected,
    this.sectionTitle = 'Recommended Destinations',
    this.limit = 10,
    this.preferredTypes,
    this.enableLocationBasedRecommendations = true,
  });

  @override
  State<RecommendedDestinations> createState() =>
      _RecommendedDestinationsState();
}

class _RecommendedDestinationsState extends State<RecommendedDestinations> {
  final FirestoreTravelService _travelService = FirestoreTravelService();
  final Location _location = Location();

  List<Destination> _destinations = [];
  bool _isLoading = true;
  bool _isOfflineMode = false;
  String? _errorMessage;
  String _loadingMessage = 'Initializing...';
  LocationData? _currentLocation;

  // Lazy loading state
  bool _isLazyLoading = false;
  int _loadedCount = 0;
  List<Destination> _allDestinations = [];

  // Cache management
  static DateTime? _lastUpdated;
  static List<Destination>? _cachedDestinations;
  static const Duration _cacheInterval = Duration(minutes: 15);

  // Safely call setState only when the widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  /// Load recommendations with lazy loading for better UI experience
  Future<void> _loadRecommendations([bool forceRefresh = false]) async {
    // Check if we have cached data that's still valid (unless forcing refresh)
    if (!forceRefresh &&
        _cachedDestinations != null &&
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < _cacheInterval) {
      _safeSetState(() {
        _destinations = _cachedDestinations!;
        _isLoading = false;
        _loadingMessage = '';
      });
      return;
    }

    try {
      _safeSetState(() {
        _isLoading = true;
        _errorMessage = null;
        _loadingMessage = 'Getting your location...';
        _destinations = []; // Clear existing destinations
      });

      // Try to get current location if enabled
      if (widget.enableLocationBasedRecommendations) {
        await _getCurrentLocation();
      }

      // Check internet connectivity first to decide loading strategy
      final connectivityService = ConnectivityService();
      
      // Try cached connectivity first for instant offline detection
      final cachedConnectivity = connectivityService.hasInternetConnectionCached();
      if (cachedConnectivity == false) {
        // We know we're offline from cache - go directly to offline mode
        _safeSetState(() {
          _loadingMessage = 'No internet - loading offline destinations...';
          _isOfflineMode = true;
        });

        final offlineDestinations = await _loadOfflineRecommendations();
        _allDestinations = offlineDestinations;

        // Start lazy loading for offline destinations
        await _lazyLoadDestinations();

        // Cache the data
        _cachedDestinations = _allDestinations;
        _lastUpdated = DateTime.now();
        return;
      }

      // Check actual connectivity (if not cached or cached shows online)
      final hasInternet = await connectivityService.hasInternetConnection();

      if (!hasInternet) {
        // No internet - go directly to offline mode
        _safeSetState(() {
          _loadingMessage = 'No internet - loading offline destinations...';
          _isOfflineMode = true;
        });

        final offlineDestinations = await _loadOfflineRecommendations();
        _allDestinations = offlineDestinations;

        // Start lazy loading for offline destinations
        await _lazyLoadDestinations();

        // Cache the data
        _cachedDestinations = _allDestinations;
        _lastUpdated = DateTime.now();
        return;
      }

      // Has internet - try online recommendations
      _safeSetState(() {
        _loadingMessage = _currentLocation != null
            ? 'Personalizing recommendations...'
            : 'Loading curated recommendations...';
      });

      List<Destination> allDestinations;

      // Try to load online recommendations
      try {
        if (_currentLocation != null) {
          allDestinations = await _travelService.getRecommendations(
            userLat: _currentLocation!.latitude!,
            userLng: _currentLocation!.longitude!,
            limit: widget.limit,
            preferredTypes: widget.preferredTypes,
          );

          // Cache for offline use
          await OfflineCacheService.cacheDestinations(allDestinations);
          await OfflineCacheService.cacheUserLocation(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          );
        } else {
          // Fallback to general recommendations
          allDestinations =
              await _travelService.getDestinations(limit: widget.limit);
        }

        _safeSetState(() {
          _isOfflineMode = false;
          _loadingMessage = 'Preparing your recommendations...';
        });

        // Store all destinations for lazy loading
        _allDestinations = allDestinations;
        
        // Start lazy loading destinations one by one
        await _lazyLoadDestinations();

      } catch (e) {
        // Online failed - fallback to offline recommendations
        print('⚠️ Online recommendations failed, trying offline: $e');
        _safeSetState(() {
          _loadingMessage = 'Loading offline recommendations...';
        });
        allDestinations = await _loadOfflineRecommendations();
        _allDestinations = allDestinations;

        _safeSetState(() {
          _isOfflineMode = true;
        });

        // Start lazy loading for offline destinations too
        await _lazyLoadDestinations();
      }

      // Cache the new data
      _cachedDestinations = _allDestinations;
      _lastUpdated = DateTime.now();

    } catch (e) {
      _safeSetState(() {
        _errorMessage = 'Failed to load recommendations: ${e.toString()}';
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  /// Lazy load destinations one by one for smoother UI experience
  Future<void> _lazyLoadDestinations() async {
    _safeSetState(() {
      _isLazyLoading = true;
      _loadedCount = 0;
    });

    // Show destinations one by one with a small delay
    for (int i = 0; i < _allDestinations.length; i++) {
      if (!mounted) break; // Safety check

      _safeSetState(() {
        _destinations = List.from(_allDestinations.take(i + 1));
        _loadedCount = i + 1;
        
        if (i == 0) {
          _isLoading = false; // Stop main loading after first destination
          _loadingMessage = 'Loading more destinations...';
        }
        
        if (i == _allDestinations.length - 1) {
          _isLazyLoading = false;
          _loadingMessage = '';
        }
      });

      // Add a small delay between each destination for smooth animation
      if (i < _allDestinations.length - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// Get current user location
  Future<void> _getCurrentLocation() async {
    try {
      _safeSetState(() {
        _loadingMessage = 'Checking location services...';
      });

      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        _safeSetState(() {
          _loadingMessage = 'Requesting location services...';
        });
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      _safeSetState(() {
        _loadingMessage = 'Checking location permission...';
      });

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        _safeSetState(() {
          _loadingMessage = 'Requesting location permission...';
        });
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      _safeSetState(() {
        _loadingMessage = 'Getting your current location...';
      });

      _currentLocation = await _location.getLocation();
    } catch (e) {
      print('⚠️ Error getting location: $e');
      _safeSetState(() {
        _loadingMessage = 'Using cached location...';
      });
      // Try to use cached location
      final cachedLocation = await OfflineCacheService.getCachedUserLocation();
      if (cachedLocation != null) {
        _currentLocation = LocationData.fromMap({
          'latitude': cachedLocation['lat'],
          'longitude': cachedLocation['lng'],
        });
      }
    }
  }

  /// Load offline recommendations
  Future<List<Destination>> _loadOfflineRecommendations() async {
    _safeSetState(() {
      _loadingMessage = 'Loading saved destinations...';
    });

    final cachedDestinations =
        await OfflineCacheService.getCachedDestinations();

    if (cachedDestinations.isNotEmpty) {
      _safeSetState(() {
        _loadingMessage = 'Found ${cachedDestinations.length} saved destinations...';
      });
      return cachedDestinations.take(widget.limit).toList();
    }

    _safeSetState(() {
      _loadingMessage = 'Searching offline database...';
    });

    // Last resort: try offline destinations from Firestore
    final offlineDestinations = await _travelService.getOfflineRecommendations(limit: widget.limit);
    
    _safeSetState(() {
      _loadingMessage = offlineDestinations.isNotEmpty
          ? 'Found ${offlineDestinations.length} offline destinations...'
          : 'No offline destinations available...';
    });

    return offlineDestinations;
  }

  /// Refresh recommendations
  Future<void> _refreshRecommendations() async {
    await _loadRecommendations(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with offline indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.sectionTitle,
                  style: AppTextStyles.h3,
                ),
              ),
              if (_isOfflineMode)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_bolt, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              // Refresh button
              IconButton(
                onPressed: _isLoading ? null : _refreshRecommendations,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: _isLoading
                    ? 'Loading recommendations...'
                    : 'Refresh recommendations',
              ),
            ],
          ),
        ),

        // Content
        if (_isLoading && _destinations.isEmpty)
          _buildLoadingState()
        else if (_errorMessage != null && _destinations.isEmpty)
          _buildErrorState()
        else if (_destinations.isEmpty)
          _buildEmptyState()
        else
          _buildDestinationsList(),
      ],
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              _loadingMessage.isNotEmpty
                  ? _loadingMessage
                  : 'Loading personalized recommendations...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (_isLazyLoading && _allDestinations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Loaded $_loadedCount of ${_allDestinations.length} destinations',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshRecommendations,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recommendations available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check your internet connection or try again later',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build destinations list
  Widget _buildDestinationsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final cardHeight = screenHeight * 0.25; // 25% of screen height

        return Column(
          children: [
            SizedBox(
              height: cardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];
                  return DestinationCard(
                    destination: destination,
                    cardHeight: cardHeight,
                    onTap: widget.onDestinationTap != null
                        ? () =>
                            widget.onDestinationTap!(destination.id, destination)
                        : null,
                    showDistance: destination.distanceKm != null,
                    isOfflineAvailable:
                        destination.isOfflineAvailable || _isOfflineMode,
                  );
                },
              ),
            ),
            // Lazy loading progress indicator
            if (_isLazyLoading && _allDestinations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading $_loadedCount of ${_allDestinations.length}...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
