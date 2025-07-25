import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/navigation/app_routes.dart';

/// Home page - central hub with search, recommendations, and quick access
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    _buildRecommendedDestinations(),
                    _buildQuickAccess(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          Text(
            'VistaGuide',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return const CustomSearchBar(
      hintText: 'Where to?',
    );
  }

  Widget _buildRecommendedDestinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recommended Destinations',
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
                itemCount: 3, // Placeholder count
                itemBuilder: (context, index) {
                  return _buildDestinationCard(context, index, cardHeight);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDestinationCard(
      BuildContext context, int index, double cardHeight) {
    final destinations = [
      {
        'title': 'The Alps',
        'subtitle':
            'Explore the majestic peaks and charming villages of the Alps.'
      },
      {
        'title': 'Maldives',
        'subtitle': 'Relax on the pristine vibrant coral reefs.'
      },
      {
        'title': 'Tokyo',
        'subtitle': 'Discover the blend of tradition and modernity.'
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.7; // 70% of screen width
    final imageHeight = cardHeight * 0.6; // 60% of card height
    final iconSize = imageHeight * 0.4; // 40% of image height

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child:
                    Icon(Icons.image, size: iconSize, color: AppColors.grey500),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      destinations[index]['title']!,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                    SizedBox(height: cardHeight * 0.02),
                    Flexible(
                      child: Text(
                        destinations[index]['subtitle']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: screenWidth * 0.032,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildQuickAccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Quick Access',
            style: AppTextStyles.h3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildQuickAccessCard(
                'Landmark Recognition',
                Icons.camera_alt,
                AppColors.primary,
                () => context.go(AppRoutes.landmarkRecognition),
              ),
              _buildQuickAccessCard(
                'Emergency Reporting',
                Icons.warning,
                AppColors.emergency,
                () => context.go(AppRoutes.emergency),
              ),
              _buildQuickAccessCard(
                'Local Events',
                Icons.event,
                AppColors.success,
                () => context.go(AppRoutes.events),
              ),
              _buildQuickAccessCard(
                'User Profile',
                Icons.person,
                AppColors.grey600,
                () => context.go(AppRoutes.profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuickAccessCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final iconSize = screenWidth * 0.08; // 8% of screen width
        final fontSize = screenWidth * 0.03; // 3% of screen width
        final padding = screenWidth * 0.03; // 3% of screen width

        return Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: iconSize, color: color),
                  SizedBox(height: padding * 0.5),
                  Flexible(
                    child: Text(
                      title,
                      style: AppTextStyles.label.copyWith(fontSize: fontSize),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
