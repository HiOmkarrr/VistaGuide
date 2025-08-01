import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navigation/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Authentication wrapper that handles routing based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while determining auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Get current route
        final String location = GoRouterState.of(context).uri.path;
        final User? user = snapshot.data;

        // Auth routes that don't require authentication
        final authRoutes = [
          AppRoutes.splash,
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.forgotPassword,
        ];

        // If user is not authenticated and trying to access protected route
        if (user == null && !authRoutes.contains(location)) {
          // Redirect to login, but this should be handled by the router redirect
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          });
        }

        // If user is authenticated and trying to access auth routes
        if (user != null &&
            authRoutes.contains(location) &&
            location != AppRoutes.splash) {
          // Redirect to home, but this should be handled by the router redirect
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go(AppRoutes.home);
            }
          });
        }

        return child;
      },
    );
  }
}
