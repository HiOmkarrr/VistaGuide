# 🔧 Setup Guide for Dynamic Destinations Service

## Required Setup Steps

### 1. **Google Places API Key** 
You need to get a Google Places API key and add it to your `.env` file.

#### Steps to get Google Places API Key:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the following APIs:
   - **Places API**
   - **Maps JavaScript API** (optional, for future map features)
   - **Geocoding API** (optional, for address conversion)
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy your API key

#### Add to `.env` file:
```properties
# Google Places API Key
GOOGLE_PLACES_API_KEY=your_actual_api_key_here

# Example (replace with your key):
# GOOGLE_PLACES_API_KEY=AIzaSyBvOkBwgyLQ4AC25R2W4RtNMiQ3uPiLBuU
```

### 2. **Firestore Security Rules**
Update your Firestore rules to allow reading destinations:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to destinations for all users
    match /destinations/{destinationId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Allow authenticated users to access their own data
    match /userData/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. **App Permissions** ✅ (Already configured)
Your AndroidManifest.xml should have location permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 4. **Test the Setup**

#### Run the app and check logs:
```bash
flutter run --debug
```

#### You should see these success messages:
```
✅ Environment variables loaded successfully
✅ Google Places API initialized successfully
🌱 Seeding Firestore with sample destinations...
✅ Successfully seeded 5 sample destinations
🎯 Getting personalized recommendations...
```

#### If you see errors:
- **"GOOGLE_PLACES_API_KEY not found"** → Add API key to .env file
- **"No destinations found"** → Sample data will be automatically seeded
- **"Permission denied"** → Update Firestore rules
- **"Location permission"** → Accept location permissions on device

### 5. **Verify Everything is Working**

#### Test checklist:
- [ ] App loads without crashes
- [ ] Location permission requested and granted
- [ ] Recommended destinations section shows sample data
- [ ] Sample destinations appear with ratings and distances
- [ ] Offline indicator works (turn off internet, refresh)
- [ ] Google Places API working (needs valid API key)

#### Sample data includes:
- Golden Gate Bridge
- Alcatraz Island  
- Stanford University
- Muir Woods National Monument
- Lombard Street

All with rich historical and educational content!

## Troubleshooting

### "Google Places API failed"
1. Check if `GOOGLE_PLACES_API_KEY` is in .env file
2. Verify API key is valid and has Places API enabled
3. Check if billing is enabled on Google Cloud project
4. Ensure API key has no restrictions that block your app

### "No destinations appearing"
1. Check Firestore connection and rules
2. Look for successful seeding logs
3. Verify user authentication is working
4. Check location permissions

### "Offline mode not working"
1. Grant location permissions
2. Let app load recommendations online first
3. Turn off internet and refresh to test cached data

## Next Steps After Setup

1. **Add your real destinations** to Firestore
2. **Customize recommendation algorithm** in FirestoreTravelService
3. **Add destination detail pages** for navigation
4. **Integrate with your AI landmark detection** model
5. **Add user reviews and ratings** functionality

Your Dynamic Destinations Service is now ready to provide intelligent, location-based recommendations! 🎉
