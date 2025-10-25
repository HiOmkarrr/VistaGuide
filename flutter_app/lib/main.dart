import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/widgets/permission_gate.dart';
import 'core/services/magic_lane_service.dart'; // This is actually Magic Lane service now
import 'core/services/simple_offline_storage_service.dart';
import 'core/services/firestore_data_seeder.dart';
import 'core/services/firestore_travel_service.dart';
import 'core/services/cache_manager_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('🚀 Starting VistaGuide App...');

  // Initialize environment variables (required for API)
  try {
    print('🔍 DEBUG: Attempting to load .env file...');
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
    print('🔍 DEBUG: Loaded ${dotenv.env.length} environment variables');
    print('🔍 DEBUG: Available keys: ${dotenv.env.keys.take(5).toList()}');
  } catch (e) {
    print('⚠️ Failed to load .env file: $e');
    print('💡 Magic Lane API features may not work properly');
    print('🔧 Check that .env file exists and has UTF-8 encoding');
    // Continue without .env - app can still work with fallbacks
  }

  // Initialize Firebase (required for auth)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Seed Firestore with sample data if empty (non-blocking)
    FirestoreDataSeeder.seedIfEmpty().catchError((e) {
      print('⚠️ Failed to seed Firestore data: $e');
    });
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    // Continue - some features may not work but app can still start
  }

  // Initialize Magic Lane API (non-blocking) - AFTER .env is loaded
  try {
    print('🔍 DEBUG: About to initialize Magic Lane service...');
    print('🔍 DEBUG: dotenv.isInitialized: ${dotenv.isInitialized}');
    if (dotenv.isInitialized) {
      print('🔍 DEBUG: dotenv has ${dotenv.env.length} variables');
      print(
          '🔍 DEBUG: MAGIC_LANE_API_KEY exists: ${dotenv.env.containsKey("MAGIC_LANE_API_KEY")}');
    }
    MagicLaneService.initialize();
    print('✅ Magic Lane API initialized (includes location autocomplete)');
  } catch (e) {
    print('⚠️ Magic Lane API initialization failed: $e');
  }

  // Initialize offline storage (non-blocking)
  try {
    final offlineStorage = SimpleOfflineStorageService();
    await offlineStorage.initialize();
    print('✅ Offline storage initialized');
  } catch (e) {
    print('⚠️ Offline storage initialization failed: $e');
    // Continue - app can work without offline storage
  }

  // Initialize cache manager (required for optimization)
  try {
    final cacheManager = CacheManagerService();
    await cacheManager.initialize();
    print('✅ Cache manager initialized');
  } catch (e) {
    print('⚠️ Cache manager initialization failed: $e');
  }

  // Initialize travel service (required for AI features)
  try {
    final travelService = FirestoreTravelService();
    await travelService.initialize();
    print('✅ Travel service initialized');
  } catch (e) {
    print('⚠️ Travel service initialization failed: $e');
  }

  print('✅ Core initialization complete, starting app UI...');

  // Start the app - Splash screen handles model download and authentication routing
  runApp(const VistaGuideApp());
}

class VistaGuideApp extends StatelessWidget {
  const VistaGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      child: MaterialApp.router(
        title: 'VistaGuide',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
