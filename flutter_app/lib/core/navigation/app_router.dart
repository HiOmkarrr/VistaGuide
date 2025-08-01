import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/landmark_recognition/presentation/pages/landmark_recognition_page.dart';
import '../../features/emergency_reporting/presentation/pages/emergency_page.dart';
import '../../features/event_alerts/presentation/pages/events_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Main router configuration for the VistaGuide app
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Authentication routes
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // Home route
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),

      // Landmark Recognition route
      GoRoute(
        path: AppRoutes.landmarkRecognition,
        builder: (context, state) => const LandmarkRecognitionPage(),
      ),

      // Emergency route
      GoRoute(
        path: AppRoutes.emergency,
        builder: (context, state) => const EmergencyPage(),
      ),

      // Events route
      GoRoute(
        path: AppRoutes.events,
        builder: (context, state) => const EventsPage(),
      ),

      // Profile route
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}
