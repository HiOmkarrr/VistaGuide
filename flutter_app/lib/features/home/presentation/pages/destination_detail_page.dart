import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/enhanced_offline_storage_service.dart';
import '../../../../core/services/firestore_travel_service.dart';
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
  final EnhancedOfflineStorageService _offlineStorage = EnhancedOfflineStorageService();
  final FirestoreTravelService _travelService = FirestoreTravelService();
  
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
      // Use pre-loaded destination if available
      if (widget.initialDestination != null) {
        _destination = widget.initialDestination;
        await _saveDestinationOffline(_destination!);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Try to load from offline storage first
      _destination = await _offlineStorage.getOfflineDestination(widget.destinationId);
      
      if (_destination != null) {
        setState(() {
          _isOfflineMode = true;
          _isLoading = false;
        });
        
        // Try to update from online in background
        _updateFromOnlineInBackground();
      } else {
        // Load from online
        await _loadFromOnline();
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load destination: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromOnline() async {
    try {
      // Try to get detailed destination info from Firestore
      final destinations = await _travelService.getDestinations(limit: 100);
      _destination = destinations.firstWhere(
        (d) => d.id == widget.destinationId,
        orElse: () => throw Exception('Destination not found'),
      );
      
      // Save to offline storage
      await _saveDestinationOffline(_destination!);
      
      setState(() {
        _isOfflineMode = false;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load destination online: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFromOnlineInBackground() async {
    try {
      final destinations = await _travelService.getDestinations(limit: 100);
      final updatedDestination = destinations.firstWhere(
        (d) => d.id == widget.destinationId,
        orElse: () => _destination!,
      );
      
      if (updatedDestination.id == widget.destinationId) {
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
    _showSnackBar(_isFavorite ? 'Added to favorites' : 'Removed from favorites');
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
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Expanded(child: _buildInfoCard('Distance', _destination!.distanceKm != null ? '${_destination!.distanceKm!.toStringAsFixed(1)} km' : 'Unknown', Icons.near_me)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Type', _destination!.type, Icons.category)),
          const SizedBox(width: 8),
          Expanded(child: _buildInfoCard('Rating', (_destination!.rating ?? 0) > 0 ? '${_destination!.rating!.toStringAsFixed(1)}/5' : 'Unrated', Icons.star)),
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
                      children: historical.relatedFigures.map(
                        (figure) => Chip(
                          label: Text(figure),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                        ),
                      ).toList(),
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
