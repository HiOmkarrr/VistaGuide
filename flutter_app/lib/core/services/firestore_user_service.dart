import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// Firestore service for user data management
/// Handles all user-related database operations including profile CRUD operations
class FirestoreUserService {
  static final FirestoreUserService _instance =
      FirestoreUserService._internal();
  factory FirestoreUserService() => _instance;
  FirestoreUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection reference for users
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create or update user profile in Firestore
  Future<void> createUserProfile(UserProfile userProfile) async {
    try {
      await _usersCollection.doc(userProfile.id).set(userProfile.toJson());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    if (currentUserId == null) return null;
    return getUserProfile(currentUserId!);
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      final updatedProfile = userProfile.copyWith(updatedAt: DateTime.now());
      await _usersCollection
          .doc(userProfile.id)
          .update(updatedProfile.toJson());
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Update specific fields in user profile
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    try {
      fields['updatedAt'] = DateTime.now().toIso8601String();
      await _usersCollection.doc(userId).update(fields);
    } catch (e) {
      throw Exception('Failed to update user fields: $e');
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  /// Stream user profile changes
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Initialize user profile with auth data (called during migration)
  Future<UserProfile> initializeUserProfile({
    required String userId,
    required String name,
    required String email,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      final userProfile = UserProfile(
        id: userId,
        name: name,
        email: email,
        phoneNumber: phoneNumber ?? '',
        location: 'Location not set',
        preferences: ['Travel', 'Photography', 'Culture'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profileImageUrl: photoURL,
      );

      await createUserProfile(userProfile);
      return userProfile;
    } catch (e) {
      debugPrint('Error initializing user profile: $e');
      rethrow;
    }
  }

  /// Stream current user profile with real-time updates
  Stream<UserProfile?> streamCurrentUserProfile() {
    if (currentUserId == null) return Stream.value(null);
    return streamUserProfile(currentUserId!);
  }

  /// Update user preferences
  Future<void> updateUserPreferences(
      String userId, List<String> preferences) async {
    try {
      await updateUserFields(userId, {'preferences': preferences});
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  /// Update user location
  Future<void> updateUserLocation(String userId, String location) async {
    try {
      await updateUserFields(userId, {'location': location});
    } catch (e) {
      throw Exception('Failed to update user location: $e');
    }
  }

  /// Update user profile image
  Future<void> updateUserProfileImage(String userId, String imageUrl) async {
    try {
      await updateUserFields(userId, {'profileImageUrl': imageUrl});
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  /// Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get multiple user profiles (for features like following/friends)
  Future<List<UserProfile>> getUserProfiles(List<String> userIds) async {
    try {
      final profiles = <UserProfile>[];

      // Firestore 'in' queries are limited to 10 items
      for (int i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.skip(i).take(10).toList();
        final querySnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          if (doc.data() != null) {
            profiles
                .add(UserProfile.fromJson(doc.data() as Map<String, dynamic>));
          }
        }
      }

      return profiles;
    } catch (e) {
      throw Exception('Failed to get user profiles: $e');
    }
  }

  /// Search users by name (for features like user discovery)
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    try {
      final querySnapshot = await _usersCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
              (doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
