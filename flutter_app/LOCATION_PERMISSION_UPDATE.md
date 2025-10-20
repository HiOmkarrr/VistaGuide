# Location Permission Update - Always Allow Required

## Overview
This update modifies the VistaGuide app to require "Always Allow" location permission. The app will not function unless the user grants permission to access location all the time, even when the app is closed.

## Changes Made

### 1. Added Permission Handler Package
**File:** `pubspec.yaml`
- Added `permission_handler: ^11.3.1` for advanced permission management including background location support

### 2. Updated Android Permissions
**File:** `android/app/src/main/AndroidManifest.xml`
- Added `ACCESS_BACKGROUND_LOCATION` permission for Android 10+ devices
- This permission is required for accessing location when the app is in the background

### 3. Updated iOS Permissions
**File:** `ios/Runner/Info.plist`
- Added `NSLocationAlwaysUsageDescription` key with appropriate description
- Updated `NSLocationAlwaysAndWhenInUseUsageDescription` to clarify background usage
- These keys are required by iOS to request "Always Allow" permission

### 4. Created Location Permission Service
**File:** `lib/core/services/location_permission_service.dart`

New service that handles location permission logic:
- **`hasAlwaysLocationPermission()`**: Checks if "Always Allow" permission is granted
- **`requestAlwaysLocationPermission()`**: Requests "Always Allow" permission from user
- **`showPermissionExplanationDialog()`**: Shows dialog explaining why background location is needed
- **`showPermissionDeniedDialog()`**: Shows dialog when user selects "Only this time" or similar limited option
- **`showOpenSettingsDialog()`**: Shows dialog when permission is permanently denied, with option to open settings
- **`ensureAlwaysLocationPermission()`**: Main method that orchestrates the permission flow with user guidance

Key Features:
- Explains to users why "Always Allow" is required
- Prompts users to try again if they select limited permissions
- Provides clear path to settings if permission is permanently denied
- Prevents app usage without proper permission

### 5. Updated Location Weather Service
**File:** `lib/core/services/location_weather_service.dart`

Modified to use the new permission service:
- Added `BuildContext` parameter to `getCurrentLocation()` and `getWeatherData()` methods
- Replaced old permission logic with new `LocationPermissionService`
- Now requires "Always Allow" permission instead of just "When in use"

### 6. Created Permission Gate Widget
**File:** `lib/core/widgets/permission_gate.dart`

New widget that acts as a gate before the main app:
- Shows loading screen while checking permissions
- Automatically requests permissions on app startup
- Shows error screen if permissions are denied
- Provides "Try Again" button for users who initially denied
- Forces app exit if user refuses to grant permission

### 7. Updated Main App Entry Point
**File:** `lib/main.dart`

Integrated permission gate:
- Wrapped entire app with `PermissionGate` widget using builder pattern
- Ensures permissions are checked before any screen is shown
- Users cannot access any app features without granting "Always Allow" permission

## User Flow

### First Time User:
1. User opens the app
2. Sees "Checking permissions..." loading screen
3. Permission explanation dialog appears with message:
   - "In order to provide you the best services, we need to access your location in the background as well"
   - Lists why background location is needed (weather, destinations, emergency services, journey tracking)
   - Shows warning: "Please select 'Allow all the time' or 'Always' when prompted"
4. User taps "Grant Permission"
5. System permission dialog appears
6. If user selects "Allow all the time" → App proceeds normally
7. If user selects "Only this time" or "While using the app" → Denied dialog appears:
   - Explains that limited permission is not sufficient
   - Offers "Try Again" to request permission again
   - Offers "Exit App" to close the application

### If Permission Permanently Denied:
1. Settings dialog appears with instructions:
   - "Location permission has been permanently denied"
   - Step-by-step guide to enable in settings
   - "Open Settings" button to navigate directly
   - "Exit App" button to close application

### Subsequent App Opens:
1. Permission gate checks existing permission
2. If "Always Allow" is granted → App loads immediately
3. If permission was revoked → Shows permission flow again

## Technical Details

### Permission States:
- **Granted (Always)**: App works normally
- **Denied**: Shows dialog asking user to grant permission
- **Permanently Denied**: Shows dialog with instructions to open settings
- **Limited (Only this time/While using)**: Shows dialog explaining why "Always" is required

### Platform Support:
- **Android**: Requires Android 10+ for background location
- **iOS**: Supports iOS permission system with "Always Allow" option

### Dialogs:
1. **Permission Explanation Dialog**: Initial dialog explaining the need
2. **Permission Denied Dialog**: When user chooses limited option
3. **Settings Dialog**: When permission is permanently denied
4. **Exit Dialog**: Final warning before closing app

## Testing Recommendations

1. **First Install**:
   - Install app freshly
   - Verify permission dialogs appear in correct order
   - Test selecting "Allow all the time" option

2. **Deny Permission**:
   - Select "Only this time" or "Deny"
   - Verify denied dialog appears
   - Test "Try Again" functionality

3. **Permanent Denial**:
   - Deny permission multiple times
   - Verify settings dialog appears
   - Test "Open Settings" button

4. **After Granting**:
   - Grant "Always Allow" permission
   - Verify app loads normally
   - Close and reopen app to verify permission persists

5. **Revoke Permission**:
   - Go to device settings
   - Revoke location permission
   - Reopen app
   - Verify permission flow triggers again

## Important Notes

1. **Media Permission**: The requirement mentioned "location and media permission" - currently only location is implemented. If media permission is also required, similar logic should be added for camera/photo library permissions.

2. **User Experience**: The strict permission requirement provides better service but may reduce app adoption. Consider:
   - Clear communication about why background location is needed
   - Privacy policy explaining data usage
   - Option to show permission benefits before requesting

3. **Battery Impact**: "Always Allow" location permission can impact battery life. Consider:
   - Implementing intelligent location fetching
   - Using geofencing instead of continuous location updates
   - Providing users with battery optimization tips

4. **Alternative Approach**: If strict "Always Allow" requirement is too restrictive, consider:
   - Allowing app to work with "While using the app" permission
   - Disabling only specific features that require background location
   - Implementing a graceful degradation strategy

## Files Modified Summary

- ✅ `pubspec.yaml` - Added permission_handler package
- ✅ `android/app/src/main/AndroidManifest.xml` - Added background location permission
- ✅ `ios/Runner/Info.plist` - Added always location usage description
- ✅ `lib/core/services/location_permission_service.dart` - New permission service (created)
- ✅ `lib/core/services/location_weather_service.dart` - Updated to use new permission logic
- ✅ `lib/core/widgets/permission_gate.dart` - New permission gate widget (created)
- ✅ `lib/main.dart` - Integrated permission gate

## Next Steps

1. Run `flutter pub get` to install the new `permission_handler` package
2. Test on physical devices (Android and iOS)
3. Verify permission dialogs appear correctly
4. Test all permission states (granted, denied, permanently denied)
5. Consider adding analytics to track permission grant/deny rates
6. Update privacy policy and app store descriptions to mention background location usage
