import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/navigation/app_routes.dart';

/// Custom bottom navigation bar widget used across the app
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.bottomNavSelected,
      unselectedItemColor: AppColors.bottomNavUnselected,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt_outlined),
          activeIcon: Icon(Icons.camera_alt),
          label: 'Landmark\nRecognition',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning_outlined),
          activeIcon: Icon(Icons.warning),
          label: 'Emergency',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.landmarkRecognition);
        break;
      case 2:
        context.go(AppRoutes.emergency);
        break;
      case 3:
        context.go(AppRoutes.events);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }
}
