import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/enhanced_offline_storage_service.dart';
import '../../../../core/services/firestore_travel_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/cache_manager_service.dart';
import '../../data/models/destination.dart';

/// Destination detail page that works both online and offline
class DestinationDetailPage extends StatefulWidget {
  final String destinationId;
  final Destination? initialDestination; // Optional pre-loaded destination

  const DestinationDetailPage({
    super.key,
    required this.destinationId,
    this.initialDestination,
  });

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  final EnhancedOfflineStorageService _offlineStorage =
      EnhancedOfflineStorageService();
  final FirestoreTravelService _travelService = FirestoreTravelService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheManagerService _cacheManager = CacheManagerService();

  Destination? _destination;
  bool _isLoading = true;
  bool _isOfflineMode = false;
  String? _errorMessage;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadDestinationDetails();
  }

  Future<void> _loadDestinationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print('🔍 LOADING DESTINATION DETAILS: ${widget.destinationId}');
      }

      // STEP 1: Use pre-loaded destination if available
      if (widget.initialDestination != null) {
        if (kDebugMode) {
          print(
              '✅ USING PRE-LOADED DESTINATION: ${widget.initialDestination!.title}');
        }

        _destination = widget.initialDestination;
        await _saveDestinationOffline(_destination!);

        // Always enhance with AI, even for pre-loaded destinations
        _enhanceWithAIInBackground();

        setState(() {
          _isLoading = false;
        });
        return;
      }

      // STEP 2: Try to load from offline storage FIRST
      if (kDebugMode) {
        print('📱 TRYING OFFLINE STORAGE...');
      }

      _destination =
          await _offlineStorage.getOfflineDestination(widget.destinationId);

      if (_destination != null) {
        if (kDebugMode) {
          print('✅ FOUND IN OFFLINE STORAGE: ${_destination!.title}');
        }

        setState(() {
          _isOfflineMode = true;
          _isLoading = false;
        });

        // Always enhance with AI, even for offline destinations
        _enhanceWithAIInBackground();
      } else {
        // STEP 3: Load from online with AI enhancement
        if (kDebugMode) {
          print('🌐 OFFLINE NOT FOUND, LOADING FROM ONLINE...');
        }

        await _loadFromOnline();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR LOADING DESTINATION: $e');
      }

      setState(() {
        _errorMessage = 'Failed to load destination: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromOnline() async {
    try {
      if (kDebugMode) {
        print('🌐 ATTEMPTING ONLINE FETCH...');
      }

      // Use the new getDestinationById method with AI enrichment
      _destination = await _travelService.getDestinationById(
        widget.destinationId,
        enrichWithAI: true, // Enable Gemini AI enrichment
      );

      if (_destination == null) {
        if (kDebugMode) {
          print('❌ DESTINATION NOT FOUND ONLINE');
        }
        throw Exception('Destination not found');
      }

      if (kDebugMode) {
        print('✅ LOADED FROM ONLINE: ${_destination!.title}');
      }

      // Save to offline storage for future use
      await _saveDestinationOffline(_destination!);

      setState(() {
        _isOfflineMode = false;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ ONLINE FETCH FAILED: $e');
      }

      setState(() {
        _errorMessage = 'Failed to load destination online: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFromOnlineInBackground() async {
    try {
      // Use the new getDestinationById method with AI enrichment for background updates
      final updatedDestination = await _travelService.getDestinationById(
        widget.destinationId,
        enrichWithAI: true, // Enable AI enrichment for latest info
      );

      if (updatedDestination != null) {
        await _saveDestinationOffline(updatedDestination);
        if (mounted) {
          setState(() {
            _destination = updatedDestination;
            _isOfflineMode = false;
          });
        }
      }
    } catch (e) {
      // Silent fail for background update
      print('Background update failed: $e');
    }
  }

  Future<void> _enhanceWithAIInBackground() async {
    if (_destination == null) return;

    try {
      if (kDebugMode) {
        print('🤖 AI ENHANCEMENT CHECK for ${_destination!.title}...');
      }

      // Initialize cache manager if needed
      await _cacheManager.initialize();

      // Check if AI enhancement is needed (cache expired + internet available)
      final isAICacheExpired =
          _cacheManager.isAIEnrichmentExpired(_destination!.id);
      final hasInternet = await _connectivityService.hasInternetConnection();

      if (kDebugMode) {
        print('🔍 AI ENHANCEMENT STATUS:');
        print('   - Cache expired: $isAICacheExpired');
        print('   - Internet available: $hasInternet');
        print(
            '   - Cache age: ${_cacheManager.getAIEnrichmentAgeInMinutes(_destination!.id)}min');
      }

      if (!isAICacheExpired) {
        if (kDebugMode) {
          print('📱 AI CACHE STILL VALID - Skipping enhancement');
        }
        return;
      }

      if (!hasInternet) {
        if (kDebugMode) {
          print('📴 NO INTERNET - Skipping AI enhancement');
        }
        return;
      }

      if (kDebugMode) {
        print(
            '🤖 STARTING AI ENHANCEMENT (cache expired + internet available)...');
      }

      // Enhance with AI in background
      final enrichedDestination =
          await _travelService.enrichDestinationWithGemini(_destination!);

      // Mark AI enhancement as fresh
      await _cacheManager.markAIEnrichmentFresh(_destination!.id);

      // Update the destination with AI-enhanced data
      await _saveDestinationOffline(enrichedDestination);

      if (mounted) {
        setState(() {
          _destination = enrichedDestination;
        });

        if (kDebugMode) {
          print('✅ AI ENHANCEMENT COMPLETED for ${enrichedDestination.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AI ENHANCEMENT FAILED: $e');
      }
      // Don't show error to user for background enhancement
    }
  }

  Future<void> _saveDestinationOffline(Destination destination) async {
    try {
      await _offlineStorage.storeDestinations([destination]);
    } catch (e) {
      print('Failed to save destination offline: $e');
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // TODO: Implement favorite persistence
    _showSnackBar(
        _isFavorite ? 'Added to favorites' : 'Removed from favorites');
  }

  void _shareDestination() {
    if (_destination == null) return;

    final shareText = '''
Check out ${_destination!.title}!

${_destination!.description ?? _destination!.subtitle}

${_destination!.coordinates != null ? 'Location: ${_destination!.coordinates!.latitude.toStringAsFixed(6)}, ${_destination!.coordinates!.longitude.toStringAsFixed(6)}' : ''}
${_destination!.historicalInfo?.briefDescription ?? ''}

Shared from VistaGuide
    ''';

    Clipboard.setData(ClipboardData(text: shareText));
    _showSnackBar('Destination info copied to clipboard');
  }

  void _getDirections() {
    if (_destination == null) return;

    // TODO: Implement directions using Magic Lane routing
    _showSnackBar('Directions feature coming soon');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
      floatingActionButton: _destination != null
          ? FloatingActionButton.extended(
              onPressed: _getDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading destination details...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load destination',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDestinationDetails,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_destination == null) return const SizedBox();

    return CustomScrollView(
      slivers: [
        _buildHeroSection(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickInfoCards(),
              _buildHistoricalSection(),
              _buildEducationalSection(),
              _buildLocationSection(),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      actions: [
        IconButton(
          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareDestination,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _destination!.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            (_destination!.imageUrl?.isNotEmpty ?? false)
                ? Image.network(
                    _destination!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            if (_isOfflineMode)
              Positioned(
                top: 100,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.place,
        size: 80,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildQuickInfoCards() {
    return Container(
      height: 100,
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
              child: _buildInfoCard(
                  'Distance',
                  _destination!.distanceKm != null
                      ? '${_destination!.distanceKm!.toStringAsFixed(1)} km'
                      : 'Unknown',
                  Icons.near_me)),
          const SizedBox(width: 8),
          Expanded(
              child:
                  _buildInfoCard('Type', _destination!.type, Icons.category)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildInfoCard(
                  'Rating',
                  (_destination!.rating ?? 0) > 0
                      ? '${_destination!.rating!.toStringAsFixed(1)}/5'
                      : 'Unrated',
                  Icons.star)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalSection() {
    if (_destination!.historicalInfo == null) return const SizedBox();

    final historical = _destination!.historicalInfo!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: ExpansionTile(
          title: const Text(
            '📜 Historical Information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (historical.briefDescription.isNotEmpty) ...[
                    Text(
                      'Brief History',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(historical.briefDescription),
                    const SizedBox(height: 16),
                  ],
                  if (historical.keyEvents.isNotEmpty) ...[
                    Text(
                      'Key Historical Events',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    ...historical.keyEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(event)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (historical.relatedFigures.isNotEmpty) ...[
                    Text(
                      'Notable Figures',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: historical.relatedFigures
                          .map(
                            (figure) => Chip(
                              label: Text(figure),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalSection() {
    if (_destination!.educationalInfo == null) return const SizedBox();

    final educational = _destination!.educationalInfo!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: ExpansionTile(
          title: const Text(
            '🎓 Educational Information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (educational.facts.isNotEmpty) ...[
                    Text(
                      'Did You Know?',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    ...educational.facts.map(
                      (fact) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 '),
                            Expanded(child: Text(fact)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (educational.importance.isNotEmpty) ...[
                    Text(
                      'Importance',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(educational.importance),
                    const SizedBox(height: 16),
                  ],
                  if (educational.culturalRelevance.isNotEmpty) ...[
                    Text(
                      'Cultural Relevance',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(educational.culturalRelevance),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📍 Location Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_destination!.coordinates != null
                        ? 'Lat: ${_destination!.coordinates!.latitude.toStringAsFixed(4)}, Lng: ${_destination!.coordinates!.longitude.toStringAsFixed(4)}'
                        : 'Location not available'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _destination!.coordinates != null
                        ? '${_destination!.coordinates!.latitude.toStringAsFixed(6)}, ${_destination!.coordinates!.longitude.toStringAsFixed(6)}'
                        : 'Coordinates not available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
