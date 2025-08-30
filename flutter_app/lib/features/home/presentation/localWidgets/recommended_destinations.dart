import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/firestore_travel_service.dart';
import '../../../../core/services/offline_cache_service.dart';
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

  // Cache management
  static DateTime? _lastUpdated;
  static List<Destination>? _cachedDestinations;
  static const Duration _cacheInterval = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  /// Load recommendations based on user location and preferences
  Future<void> _loadRecommendations() async {
    // Check if we have cached data that's still valid
    if (_cachedDestinations != null &&
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < _cacheInterval) {
      setState(() {
        _destinations = _cachedDestinations!;
        _isLoading = false;
        _loadingMessage = '';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _loadingMessage = 'Getting your location...';
      });

      // Try to get current location if enabled
      if (widget.enableLocationBasedRecommendations) {
        await _getCurrentLocation();
      }

      setState(() {
        _loadingMessage = _currentLocation != null
            ? 'Finding destinations near you...'
            : 'Loading curated recommendations...';
      });

      List<Destination> destinations;

      // Try to load online recommendations first
      try {
        setState(() {
          _loadingMessage = 'Personalizing recommendations...';
        });

        if (_currentLocation != null) {
          destinations = await _travelService.getRecommendations(
            userLat: _currentLocation!.latitude!,
            userLng: _currentLocation!.longitude!,
            limit: widget.limit,
            preferredTypes: widget.preferredTypes,
          );

          // Cache for offline use
          await OfflineCacheService.cacheDestinations(destinations);
          await OfflineCacheService.cacheUserLocation(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          );
        } else {
          // Fallback to general recommendations
          destinations =
              await _travelService.getDestinations(limit: widget.limit);
        }

        setState(() {
          _isOfflineMode = false;
          _loadingMessage = 'Finalizing recommendations...';
        });
      } catch (e) {
        // Fallback to offline recommendations
        print('⚠️ Online recommendations failed, trying offline: $e');
        setState(() {
          _loadingMessage = 'Loading offline recommendations...';
        });
        destinations = await _loadOfflineRecommendations();

        setState(() {
          _isOfflineMode = true;
        });
      }

      setState(() {
        _destinations = destinations;
        _isLoading = false;
        _loadingMessage = '';

        // Cache the new data
        _cachedDestinations = destinations;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations: ${e.toString()}';
        _isLoading = false;
        _loadingMessage = '';
      });
    }
  }

  /// Get current user location
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _loadingMessage = 'Checking location services...';
      });

      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loadingMessage = 'Requesting location services...';
        });
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      setState(() {
        _loadingMessage = 'Checking location permission...';
      });

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        setState(() {
          _loadingMessage = 'Requesting location permission...';
        });
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      setState(() {
        _loadingMessage = 'Getting your current location...';
      });

      _currentLocation = await _location.getLocation();
    } catch (e) {
      print('⚠️ Error getting location: $e');
      setState(() {
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
    setState(() {
      _loadingMessage = 'Loading cached destinations...';
    });

    final cachedDestinations =
        await OfflineCacheService.getCachedDestinations();

    if (cachedDestinations.isNotEmpty) {
      return cachedDestinations.take(widget.limit).toList();
    }

    setState(() {
      _loadingMessage = 'Fetching offline recommendations...';
    });

    // Last resort: try offline destinations from Firestore
    return await _travelService.getOfflineRecommendations(limit: widget.limit);
  }

  /// Refresh recommendations
  Future<void> _refreshRecommendations() async {
    await _loadRecommendations();
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh recommendations',
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

        return SizedBox(
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
        );
      },
    );
  }
}
