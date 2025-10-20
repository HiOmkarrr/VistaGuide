import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/location_permission_service.dart';

/// Widget that ensures location permissions are granted before proceeding
class PermissionGate extends StatefulWidget {
  final Widget child;

  const PermissionGate({
    super.key,
    required this.child,
  });

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  final _permissionService = LocationPermissionService();
  bool _isChecking = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    // Delay the permission check slightly to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      // Check if we already have the permission
      final hasPermission = await _permissionService.hasAlwaysLocationPermission();
      print('📍 Has always permission: $hasPermission');

      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
          _isChecking = false;
        });
      }
    } catch (e) {
      print('❌ Error checking permissions: $e');
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _requestPermission(BuildContext dialogContext) async {
    if (!mounted) return;

    try {
      print('📍 Requesting permission...');
      
      // Use the ensureAlwaysLocationPermission with the dialog context (which has MaterialLocalizations)
      final granted = await _permissionService.ensureAlwaysLocationPermission(dialogContext);
      
      print('📍 Permission result: $granted');
      
      if (mounted) {
        setState(() {
          _hasPermission = granted;
        });
      }
    } catch (e) {
      print('❌ Error requesting permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Error requesting permission: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If still checking, show loading within a MaterialApp for proper context
    if (_isChecking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking permissions...'),
              ],
            ),
          ),
        ),
      );
    }

    // If permission not granted, show permission request screen
    if (!_hasPermission) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Location Permission Required',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'VistaGuide needs access to your location at all times to provide:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Icon(Icons.cloud, color: Colors.blue),
                          title: Text('Real-time weather updates'),
                        ),
                        ListTile(
                          leading: Icon(Icons.explore, color: Colors.blue),
                          title: Text('Nearby destination recommendations'),
                        ),
                        ListTile(
                          leading: Icon(Icons.emergency, color: Colors.blue),
                          title: Text('Emergency services'),
                        ),
                        ListTile(
                          leading: Icon(Icons.map, color: Colors.blue),
                          title: Text('Journey tracking'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '⚠️ Please select "Allow all the time" or "Always" when prompted',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Builder(
                      builder: (innerContext) => ElevatedButton.icon(
                        onPressed: () => _requestPermission(innerContext),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Grant Location Permission'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                      child: const Text('Exit App'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Permission granted, return the actual app
    return widget.child;
  }
}
