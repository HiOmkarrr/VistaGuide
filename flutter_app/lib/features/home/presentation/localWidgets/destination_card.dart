import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/dynamic_image_service.dart';
import '../../data/models/destination.dart';

/// Enhanced destination card widget with responsive design and dynamic images
class DestinationCard extends StatefulWidget {
  final Destination destination;
  final double cardHeight;
  final VoidCallback? onTap;
  final bool showDistance;
  final bool isOfflineAvailable;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.cardHeight,
    this.onTap,
    this.showDistance = false,
    this.isOfflineAvailable = false,
  });

  @override
  State<DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<DestinationCard> {
  final DynamicImageService _imageService = DynamicImageService();
  String? _imageUrl;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  /// Load image dynamically
  Future<void> _loadImage() async {
    // Check if image is already cached
    final cachedUrl = _imageService.getCachedImageUrl(widget.destination.id);
    if (cachedUrl != null) {
      setState(() {
        _imageUrl = cachedUrl;
      });
      return;
    }

    setState(() {
      _isLoadingImage = true;
    });

    try {
      final imageUrl = await _imageService.getDestinationImageUrl(
        destinationId: widget.destination.id,
        destinationName: widget.destination.title,
        firestoreImageUrl: widget.destination.imageUrl,
        firestoreImages: widget.destination.images,
        destinationType: widget.destination.type,
      );

      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading image for ${widget.destination.title}: $e');
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.7; // 70% of screen width
    final imageHeight = widget.cardHeight * 0.6; // 60% of card height
    final iconSize = imageHeight * 0.4; // 40% of image height

    return Container(
      width: cardWidth,
      height: widget.cardHeight,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      child: Card(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildImage(imageHeight, iconSize),
              ),
              Expanded(
                flex: 2,
                child: _buildContent(screenWidth, widget.cardHeight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(double imageHeight, double iconSize) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Stack(
        children: [
          // Image with CachedNetworkImage
          if (_imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: _imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.grey200,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: iconSize,
                    color: AppColors.grey500,
                  ),
                ),
              ),
            )
          else if (_isLoadingImage)
            Container(
              color: AppColors.grey200,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else
            // Fallback placeholder
            Center(
              child: Icon(
                Icons.image,
                size: iconSize,
                color: AppColors.grey500,
              ),
            ),

          // Rating badge
          if (widget.destination.rating != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      widget.destination.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Offline indicator
          if (widget.isOfflineAvailable)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.offline_pin,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),

          // Distance indicator
          if (widget.showDistance && widget.destination.distanceKm != null)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.destination.distanceKm!.toStringAsFixed(1)}km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(double screenWidth, double cardHeight) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              widget.destination.title,
              style: AppTextStyles.h4.copyWith(
                fontSize: screenWidth * 0.04,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              widget.destination.subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: screenWidth * 0.03,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Show destination type if available
          if (widget.destination.type != 'attraction')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.destination.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.025,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

