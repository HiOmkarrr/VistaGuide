// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlzP0kfjHWz3WplY56wj4sbtLOngIphZ0',
    appId: '1:585843765512:web:0776785d3d456e0d817cbd',
    messagingSenderId: '585843765512',
    projectId: 'vistaguide-54922',
    authDomain: 'vistaguide-54922.firebaseapp.com',
    storageBucket: 'vistaguide-54922.firebasestorage.app',
    measurementId: 'G-HP9XSDVQQC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADV8hOYYKyEQhVBzHTB2SnaMtC-l1Kfpo',
    appId: '1:585843765512:android:c9b0f86b57f4e247817cbd',
    messagingSenderId: '585843765512',
    projectId: 'vistaguide-54922',
    storageBucket: 'vistaguide-54922.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrAorjwNDiKOIywmpljs_ifWBa95fbzVw',
    appId: '1:585843765512:ios:3c57d9cd31b1e857817cbd',
    messagingSenderId: '585843765512',
    projectId: 'vistaguide-54922',
    storageBucket: 'vistaguide-54922.firebasestorage.app',
    iosBundleId: 'com.example.flutterApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCrAorjwNDiKOIywmpljs_ifWBa95fbzVw',
    appId: '1:585843765512:ios:3c57d9cd31b1e857817cbd',
    messagingSenderId: '585843765512',
    projectId: 'vistaguide-54922',
    storageBucket: 'vistaguide-54922.firebasestorage.app',
    iosBundleId: 'com.example.flutterApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBlzP0kfjHWz3WplY56wj4sbtLOngIphZ0',
    appId: '1:585843765512:web:f97609ca3e6421a8817cbd',
    messagingSenderId: '585843765512',
    projectId: 'vistaguide-54922',
    authDomain: 'vistaguide-54922.firebaseapp.com',
    storageBucket: 'vistaguide-54922.firebasestorage.app',
    measurementId: 'G-0529HBXNNH',
  );
}
