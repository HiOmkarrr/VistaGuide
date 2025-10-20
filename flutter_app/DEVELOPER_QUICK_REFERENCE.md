# Developer Quick Reference - Location Permission Implementation

## Quick Start

### Installation Complete ✅
The `permission_handler` package has been installed. You're ready to test!

### Testing the App

1. **Clean build** (recommended):
   ```bash
   cd flutter_app
   flutter clean
   flutter pub get
   flutter run
   ```

2. **On First Run**:
   - App will show "Checking permissions..." screen
   - Permission explanation dialog will appear
   - System permission dialog follows
   - **IMPORTANT**: Select "Allow all the time" or "Always" option

## Key Classes Reference

### 1. LocationPermissionService
**Path**: `lib/core/services/location_permission_service.dart`

```dart
final permissionService = LocationPermissionService();

// Check if already granted
bool hasPermission = await permissionService.hasAlwaysLocationPermission();

// Request with UI flow (requires BuildContext)
bool granted = await permissionService.ensureAlwaysLocationPermission(context);

// Get current status
PermissionStatus status = await permissionService.getLocationAlwaysStatus();
```

### 2. LocationWeatherService (Updated)
**Path**: `lib/core/services/location_weather_service.dart`

```dart
final locationService = LocationWeatherService();

// Now requires BuildContext for permission dialogs
Position? position = await locationService.getCurrentLocation(context: context);

WeatherData? weather = await locationService.getWeatherData(context: context);
```

### 3. PermissionGate Widget
**Path**: `lib/core/widgets/permission_gate.dart`

Automatically wraps the entire app via `main.dart`. No manual implementation needed.

## Usage Examples

### Example 1: Getting Location in a Widget
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final locationService = LocationWeatherService();
  Position? currentPosition;

  Future<void> _getLocation() async {
    // Pass context to enable permission dialogs if needed
    final position = await locationService.getCurrentLocation(context: context);
    
    if (position != null) {
      setState(() {
        currentPosition = position;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _getLocation,
      child: Text('Get My Location'),
    );
  }
}
```

### Example 2: Checking Permission Status
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> checkLocationPermission() async {
  final status = await Permission.locationAlways.status;
  
  if (status.isGranted) {
    print('Always location permission granted');
  } else if (status.isDenied) {
    print('Permission denied');
  } else if (status.isPermanentlyDenied) {
    print('Permission permanently denied - open settings');
    await openAppSettings();
  }
}
```

### Example 3: Manual Permission Request (Advanced)
```dart
final permissionService = LocationPermissionService();

// Show custom explanation before requesting
final shouldRequest = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Location Needed'),
    content: Text('We need location for...'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('Continue'),
      ),
    ],
  ),
);

if (shouldRequest == true) {
  final granted = await permissionService.requestAlwaysLocationPermission();
  // Handle result...
}
```

## Platform-Specific Notes

### Android
- **Minimum SDK**: Android 10 (API 29) for `ACCESS_BACKGROUND_LOCATION`
- **Permission Dialog**: Two-step process
  1. First: "Allow while using the app" or "Deny"
  2. Second (if first granted): "Allow all the time" or "Deny"
- **Testing**: Use real device or emulator with Google Play Services

### iOS
- **Minimum Version**: iOS 11+
- **Permission Dialog**: One-step with options:
  - "Allow While Using App"
  - "Allow Once"
  - "Don't Allow"
  - Later shows: "Change to Always Allow" option
- **Testing**: Use real device or simulator

## Troubleshooting

### Issue: Permission dialog not showing
**Solution**: 
1. Uninstall app completely
2. Reinstall with `flutter run`
3. Check device settings → Apps → VistaGuide → Permissions

### Issue: "Permanently denied" on first try
**Solution**:
1. Clear app data from device settings
2. Or uninstall and reinstall

### Issue: App crashes on startup
**Solution**:
1. Check Android/iOS logs
2. Verify `permission_handler` package is installed: `flutter pub get`
3. Clean build: `flutter clean && flutter pub get`

### Issue: iOS not showing "Always Allow" option
**Solution**:
1. In iOS, "Always Allow" option appears in a follow-up prompt
2. User must first grant "While Using App"
3. Later, iOS will prompt to upgrade to "Always Allow"
4. Or: Settings → VistaGuide → Location → Always

## Testing Checklist

- [ ] Fresh install - permission dialog appears
- [ ] Select "Always Allow" - app works
- [ ] Select "Only this time" - denied dialog appears
- [ ] Deny permission - exit dialog appears
- [ ] Revoke permission in settings - app re-requests on next launch
- [ ] Test "Try Again" button functionality
- [ ] Test "Open Settings" button functionality
- [ ] Verify location features work after granting permission
- [ ] Test on both Android and iOS
- [ ] Test on different OS versions (Android 10+, iOS 13+)

## Important Methods Summary

| Method | Class | Purpose |
|--------|-------|---------|
| `hasAlwaysLocationPermission()` | LocationPermissionService | Check if already granted |
| `requestAlwaysLocationPermission()` | LocationPermissionService | Request without UI |
| `ensureAlwaysLocationPermission(context)` | LocationPermissionService | Full flow with dialogs |
| `getCurrentLocation(context: context)` | LocationWeatherService | Get current position |
| `getWeatherData(context: context)` | LocationWeatherService | Get weather + location |

## Build Commands

### Android
```bash
cd flutter_app
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
cd flutter_app
flutter build ios --release
```

### Debug
```bash
cd flutter_app
flutter run --debug
```

## Logs to Monitor

### Android Logcat
```bash
adb logcat | grep -i "permission\|location"
```

### iOS Console
Check Xcode console for permission-related logs

### Flutter Logs
```bash
flutter logs
```

Look for:
- "Location permission granted"
- "Permission denied"
- "Opening settings"

## Additional Resources

- [permission_handler package](https://pub.dev/packages/permission_handler)
- [Android location permissions](https://developer.android.com/training/location/permissions)
- [iOS location permissions](https://developer.apple.com/documentation/corelocation/requesting_authorization_to_use_location_services)

## Need Help?

Check these files for implementation details:
1. `LOCATION_PERMISSION_UPDATE.md` - Full documentation
2. `lib/core/services/location_permission_service.dart` - Permission logic
3. `lib/core/widgets/permission_gate.dart` - Gate widget
4. `lib/main.dart` - App integration
