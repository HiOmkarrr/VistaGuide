import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/destination.dart';
import 'destination_card.dart';

/// Reusable recommended destinations section widget
class RecommendedDestinations extends StatelessWidget {
  final List<Destination> destinations;
  final Function(String destinationId)? onDestinationTap;
  final String sectionTitle;

  const RecommendedDestinations({
    super.key,
    required this.destinations,
    this.onDestinationTap,
    this.sectionTitle = 'Recommended Destinations',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            sectionTitle,
            style: AppTextStyles.h3,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            final cardHeight = screenHeight * 0.25; // 25% of screen height

            return SizedBox(
              height: cardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  return DestinationCard(
                    destination: destination,
                    cardHeight: cardHeight,
                    onTap: onDestinationTap != null
                        ? () => onDestinationTap!(destination.id)
                        : null,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
