import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/destination.dart';

/// Reusable destination card widget with responsive design
class DestinationCard extends StatelessWidget {
  final Destination destination;
  final double cardHeight;
  final VoidCallback? onTap;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.cardHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.7; // 70% of screen width
    final imageHeight = cardHeight * 0.6; // 60% of card height
    final iconSize = imageHeight * 0.4; // 40% of image height

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(imageHeight, iconSize),
              Expanded(
                child: _buildContent(screenWidth, cardHeight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(double imageHeight, double iconSize) {
    return Container(
      height: imageHeight,
      decoration: const BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.image,
              size: iconSize,
              color: AppColors.grey500,
            ),
          ),
          if (destination.rating != null)
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
                      destination.rating!.toString(),
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
        ],
      ),
    );
  }

  Widget _buildContent(double screenWidth, double cardHeight) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            destination.title,
            style: AppTextStyles.h4.copyWith(
              fontSize: screenWidth * 0.045,
            ),
          ),
          SizedBox(height: cardHeight * 0.02),
          Flexible(
            child: Text(
              destination.subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: screenWidth * 0.032,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
