import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

/// Service to handle location permission requests with strict "always" requirement
class LocationPermissionService {
  static final LocationPermissionService _instance =
      LocationPermissionService._internal();
  factory LocationPermissionService() => _instance;
  LocationPermissionService._internal();

  /// Check if the app has "always" location permission
  Future<bool> hasAlwaysLocationPermission() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        return false;
      }

      // For Android 10+ and iOS, check for "always" permission
      final status = await Permission.locationAlways.status;
      debugPrint('📍 Location always permission status: $status');
      
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking always location permission: $e');
      return false;
    }
  }

  /// Request "always" location permission from the user
  /// Returns true if granted, false otherwise
  Future<bool> requestAlwaysLocationPermission() async {
    try {
      // First check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 Requesting permission - service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('⚠️ Location service not enabled');
        return false;
      }

      // Request "when in use" permission first (required on some platforms)
      debugPrint('📍 Requesting "when in use" permission...');
      final whenInUseStatus = await Permission.location.request();
      debugPrint('📍 When in use status: $whenInUseStatus');
      
      if (whenInUseStatus.isDenied || whenInUseStatus.isPermanentlyDenied) {
        debugPrint('⚠️ When in use permission denied');
        return false;
      }

      // Then request "always" permission
      debugPrint('📍 Requesting "always" permission...');
      final alwaysStatus = await Permission.locationAlways.request();
      debugPrint('📍 Always status: $alwaysStatus');
      
      return alwaysStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting always location permission: $e');
      return false;
    }
  }

  /// Show a dialog explaining why "always" permission is needed
  Future<bool?> showPermissionExplanationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In order to provide you the best services, we need to access your location in the background as well.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'This allows us to:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Provide real-time weather updates'),
                Text('• Recommend nearby destinations'),
                Text('• Enable emergency services'),
                Text('• Track your journeys'),
                SizedBox(height: 16),
                Text(
                  'Please select "Allow all the time" or "Always" when prompted.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Exit App'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Grant Permission'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  /// Show a dialog when user denies "always" permission
  Future<bool?> showPermissionDeniedDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Not Granted'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You selected a limited location permission option.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'VistaGuide requires "Always Allow" permission to function properly.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Would you like to try again and grant the necessary permissions?',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Exit App'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  /// Show a dialog when permission is permanently denied
  Future<bool?> showOpenSettingsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location permission has been permanently denied.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'To use VistaGuide, please enable location access in your device settings:',
                ),
                SizedBox(height: 8),
                Text('1. Open Settings'),
                Text('2. Go to Apps → VistaGuide'),
                Text('3. Select Permissions → Location'),
                Text('4. Choose "Allow all the time"'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Exit App'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  /// Main method to ensure "always" location permission with user guidance
  /// Returns true if permission is granted, false otherwise
  Future<bool> ensureAlwaysLocationPermission(BuildContext context) async {
    try {
      debugPrint('📍 Starting ensureAlwaysLocationPermission...');
      
      // Check if we already have the permission
      if (await hasAlwaysLocationPermission()) {
        debugPrint('✅ Already have always location permission');
        return true;
      }

      debugPrint('📍 Showing explanation dialog...');
      // Show explanation dialog
      final shouldRequest = await showPermissionExplanationDialog(context);
      debugPrint('📍 Should request: $shouldRequest');
      
      if (shouldRequest != true) {
        debugPrint('⚠️ User chose not to grant permission');
        return false; // User chose to exit
      }

      debugPrint('📍 Requesting permission...');
      // Request permission
      final granted = await requestAlwaysLocationPermission();
      debugPrint('📍 Permission granted: $granted');
      
      if (granted) {
        debugPrint('✅ Permission successfully granted');
        return true;
      }

      // Check if permission is permanently denied
      final alwaysStatus = await Permission.locationAlways.status;
      debugPrint('📍 Final status after request: $alwaysStatus');
      
      if (alwaysStatus.isPermanentlyDenied) {
        debugPrint('⚠️ Permission permanently denied, showing settings dialog');
        // Show dialog to open settings
        final openSettings = await showOpenSettingsDialog(context);
        if (openSettings == true) {
          await openAppSettings();
          // Return false - user needs to manually enable and restart app
          return false;
        }
        return false;
      }

      debugPrint('📍 Permission denied, showing retry dialog');
      // Permission was denied but not permanently
      // Show dialog asking to try again
      final tryAgain = await showPermissionDeniedDialog(context);
      if (tryAgain == true) {
        debugPrint('📍 User wants to try again');
        // Recursively try again
        return await ensureAlwaysLocationPermission(context);
      }

      debugPrint('⚠️ User declined to try again');
      return false;
    } catch (e) {
      debugPrint('❌ Error in ensureAlwaysLocationPermission: $e');
      return false;
    }
  }

  /// Check permission status without requesting
  Future<PermissionStatus> getLocationAlwaysStatus() async {
    return await Permission.locationAlways.status;
  }

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
