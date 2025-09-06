import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/emergency_reporting/data/models/emergency_contact.dart';

/// Firebase Cloud Messaging Service for handling push notifications
/// Used for both OTP delivery and emergency SMS notifications
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  String? _fcmToken;
  StreamController<RemoteMessage>? _messageStreamController;
  
  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing Firebase Cloud Messaging');
      
      // Request permission for iOS
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      debugPrint('🔔 FCM permission status: ${settings.authorizationStatus}');
      
      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔔 FCM Token: $_fcmToken');
      
      // Store token in preferences
      if (_fcmToken != null) {
        await _storeFCMToken(_fcmToken!);
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔔 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _storeFCMToken(newToken);
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Check if app was launched from notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 App launched from notification: ${initialMessage.data}');
        _handleMessageOpenedApp(initialMessage);
      }
      
      debugPrint('✅ Firebase Cloud Messaging initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }
  
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Received foreground message: ${message.messageId}');
    
    // Log message details for debugging
    debugPrint('🔔 Message data: ${message.data}');
    debugPrint('🔔 Message notification: ${message.notification?.title} - ${message.notification?.body}');
    
    // Broadcast to listeners
    _messageStreamController?.add(message);
  }
  
  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 App opened from notification: ${message.data}');
    
    final messageType = message.data['type'];
    switch (messageType) {
      case 'emergency_response':
        _handleEmergencyResponse(message);
        break;
      case 'otp':
        _handleOTPMessage(message);
        break;
      default:
        debugPrint('🔔 Unknown message type: $messageType');
    }
  }
  
  /// Handle emergency response messages
  void _handleEmergencyResponse(RemoteMessage message) {
    final responderId = message.data['responder_id'];
    final response = message.data['response'];
    final location = message.data['location'];
    
    debugPrint('🚨 Emergency response received from $responderId: $response');
    // TODO: Navigate to emergency response screen or show detailed dialog
  }
  
  /// Handle OTP messages
  void _handleOTPMessage(RemoteMessage message) {
    final otp = message.data['otp'];
    final phoneNumber = message.data['phone_number'];
    
    debugPrint('🔑 OTP received via FCM: $otp for $phoneNumber');
    // TODO: Auto-fill OTP in verification screen
  }
  
  
  /// Send emergency alert via FCM to emergency contacts
  Future<FCMResult> sendEmergencyAlert({
    required List<EmergencyContact> contacts,
    required Map<String, dynamic> locationData,
    required String userName,
  }) async {
    try {
      debugPrint('🚨 Sending emergency alert via FCM to ${contacts.length} contacts');
      
      final List<String> successfulContacts = [];
      final List<String> failedContacts = [];
      
      for (final contact in contacts) {
        try {
          // In a real implementation, you would:
          // 1. Get the contact's FCM token from your backend
          // 2. Send the notification via your backend server
          // 3. Handle delivery confirmations
          
          final result = await _sendEmergencyFCM(
            contactName: contact.name,
            phoneNumber: contact.phoneNumber,
            locationData: locationData,
            userName: userName,
          );
          
          if (result) {
            successfulContacts.add(contact.name);
          } else {
            failedContacts.add(contact.name);
          }
        } catch (e) {
          debugPrint('❌ Failed to send FCM to ${contact.name}: $e');
          failedContacts.add(contact.name);
        }
        
        // Add small delay between sends to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      return FCMResult(
        success: successfulContacts.isNotEmpty,
        message: 'Emergency alert sent to ${successfulContacts.length} contacts',
        successfulContacts: successfulContacts,
        failedContacts: failedContacts,
      );
    } catch (e) {
      debugPrint('❌ Error sending emergency alert: $e');
      return FCMResult(
        success: false,
        message: 'Failed to send emergency alert: $e',
        failedContacts: contacts.map((c) => c.name).toList(),
      );
    }
  }
  
  /// Send OTP via FCM
  Future<FCMResult> sendOTPViaPush({
    required String phoneNumber,
    required String otp,
    String? userName,
  }) async {
    try {
      debugPrint('🔑 Sending OTP via FCM to $phoneNumber');
      
      // In a real implementation, this would be sent via your backend server
      final success = await _sendOTPFCM(
        phoneNumber: phoneNumber,
        otp: otp,
        userName: userName,
      );
      
      return FCMResult(
        success: success,
        message: success ? 'OTP sent via push notification' : 'Failed to send OTP via push',
      );
    } catch (e) {
      debugPrint('❌ Error sending OTP via FCM: $e');
      return FCMResult(
        success: false,
        message: 'Failed to send OTP: $e',
      );
    }
  }
  
  /// Simulate sending emergency FCM (in real app, this would be done via backend)
  Future<bool> _sendEmergencyFCM({
    required String contactName,
    required String phoneNumber,
    required Map<String, dynamic> locationData,
    required String userName,
  }) async {
    try {
      // Simulate API call to backend
      await Future.delayed(const Duration(milliseconds: 500));
      
      // In production, you would call your backend API like:
      // final response = await http.post(
      //   Uri.parse('https://your-backend.com/api/send-emergency-fcm'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'contact_phone': phoneNumber,
      //     'message_type': 'emergency_alert',
      //     'data': {
      //       'user_name': userName,
      //       'location': locationData,
      //       'timestamp': DateTime.now().toIso8601String(),
      //     }
      //   }),
      // );
      // return response.statusCode == 200;
      
      debugPrint('📱 Emergency FCM sent to $contactName ($phoneNumber)');
      return true; // Simulate success for demo
    } catch (e) {
      debugPrint('❌ Error sending emergency FCM: $e');
      return false;
    }
  }
  
  /// Simulate sending OTP FCM (in real app, this would be done via backend)
  Future<bool> _sendOTPFCM({
    required String phoneNumber,
    required String otp,
    String? userName,
  }) async {
    try {
      // Simulate API call to backend
      await Future.delayed(const Duration(milliseconds: 300));
      
      debugPrint('🔑 OTP FCM sent to $phoneNumber: $otp');
      return true; // Simulate success for demo
    } catch (e) {
      debugPrint('❌ Error sending OTP FCM: $e');
      return false;
    }
  }
  
  /// Store FCM token in SharedPreferences
  Future<void> _storeFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      debugPrint('✅ FCM token stored successfully');
    } catch (e) {
      debugPrint('❌ Error storing FCM token: $e');
    }
  }
  
  /// Get stored FCM token
  Future<String?> getFCMToken() async {
    if (_fcmToken != null) return _fcmToken;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken = prefs.getString('fcm_token');
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }
  
  /// Subscribe to topic for emergency updates
  Future<void> subscribeToEmergencyTopic(String userId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('emergency_$userId');
      debugPrint('✅ Subscribed to emergency topic for user: $userId');
    } catch (e) {
      debugPrint('❌ Error subscribing to emergency topic: $e');
    }
  }
  
  /// Unsubscribe from emergency topic
  Future<void> unsubscribeFromEmergencyTopic(String userId) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('emergency_$userId');
      debugPrint('✅ Unsubscribed from emergency topic for user: $userId');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from emergency topic: $e');
    }
  }
  
  /// Get message stream for listening to incoming messages
  Stream<RemoteMessage> get messageStream {
    _messageStreamController ??= StreamController<RemoteMessage>.broadcast();
    return _messageStreamController!.stream;
  }
  
  /// Dispose resources
  void dispose() {
    _messageStreamController?.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔔 Handling background message: ${message.messageId}');
  
  // Handle background message processing
  final messageType = message.data['type'];
  switch (messageType) {
    case 'emergency_response':
      // Store emergency response for later processing
      await _storeEmergencyResponse(message.data);
      break;
    case 'otp':
      // Store OTP for auto-fill when app opens
      await _storeOTPForAutoFill(message.data);
      break;
  }
}

/// Store emergency response data
Future<void> _storeEmergencyResponse(Map<String, dynamic> data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final responses = prefs.getStringList('emergency_responses') ?? [];
    responses.add(jsonEncode({
      ...data,
      'received_at': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList('emergency_responses', responses);
  } catch (e) {
    debugPrint('❌ Error storing emergency response: $e');
  }
}

/// Store OTP for auto-fill
Future<void> _storeOTPForAutoFill(Map<String, dynamic> data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_otp_autofill', jsonEncode({
      ...data,
      'received_at': DateTime.now().toIso8601String(),
    }));
  } catch (e) {
    debugPrint('❌ Error storing OTP for auto-fill: $e');
  }
}

/// FCM operation result
class FCMResult {
  final bool success;
  final String message;
  final List<String> successfulContacts;
  final List<String> failedContacts;

  FCMResult({
    required this.success,
    required this.message,
    this.successfulContacts = const [],
    this.failedContacts = const [],
  });
}
