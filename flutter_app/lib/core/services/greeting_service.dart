import 'package:firebase_auth/firebase_auth.dart';

/// Service to generate time-based greetings
class GreetingService {
  static final GreetingService _instance = GreetingService._internal();
  factory GreetingService() => _instance;
  GreetingService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Get current time-based greeting
  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  /// Get the current user's name
  String getUserName() {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null && currentUser.displayName != null) {
      // Extract first name if full name is provided
      final fullName = currentUser.displayName!;
      final parts = fullName.split(' ');
      return parts.isNotEmpty ? parts.first : 'User';
    }
    return 'User';
  }

  /// Get complete greeting message
  String getGreetingMessage() {
    final greeting = getGreeting();
    final userName = getUserName();
    return '$greeting $userName!';
  }
}
