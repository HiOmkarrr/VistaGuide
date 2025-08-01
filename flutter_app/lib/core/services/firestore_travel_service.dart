import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/home/data/models/destination.dart';

/// Firestore service for travel-related data
/// Handles destinations, favorites, travel history, and recommendations
class FirestoreTravelService {
  static final FirestoreTravelService _instance =
      FirestoreTravelService._internal();
  factory FirestoreTravelService() => _instance;
  FirestoreTravelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection references
  CollectionReference get _destinationsCollection =>
      _firestore.collection('destinations');
  CollectionReference get _userDataCollection =>
      _firestore.collection('userData');

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get user-specific document reference
  DocumentReference? get _currentUserDoc =>
      currentUserId != null ? _userDataCollection.doc(currentUserId!) : null;

  // ==================== DESTINATIONS ====================

  /// Get all destinations
  Future<List<Destination>> getDestinations({int limit = 20}) async {
    try {
      final querySnapshot = await _destinationsCollection
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Destination.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get destinations: $e');
    }
  }

  /// Get destination by ID
  Future<Destination?> getDestination(String destinationId) async {
    try {
      final doc = await _destinationsCollection.doc(destinationId).get();

      if (doc.exists && doc.data() != null) {
        return Destination.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get destination: $e');
    }
  }

  /// Search destinations
  Future<List<Destination>> searchDestinations(String query,
      {int limit = 20}) async {
    try {
      final querySnapshot = await _destinationsCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Destination.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to search destinations: $e');
    }
  }

  /// Get destinations by tags
  Future<List<Destination>> getDestinationsByTags(List<String> tags,
      {int limit = 20}) async {
    try {
      final querySnapshot = await _destinationsCollection
          .where('tags', arrayContainsAny: tags)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Destination.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get destinations by tags: $e');
    }
  }

  // ==================== FAVORITES ====================

  /// Get user's favorite destinations
  Future<List<String>> getUserFavorites() async {
    if (currentUserId == null) return [];

    try {
      final doc = await _currentUserDoc!.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['favoriteDestinations'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get user favorites: $e');
    }
  }

  /// Add destination to favorites
  Future<void> addToFavorites(String destinationId) async {
    if (currentUserId == null) return;

    try {
      await _currentUserDoc!.set({
        'favoriteDestinations': FieldValue.arrayUnion([destinationId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Remove destination from favorites
  Future<void> removeFromFavorites(String destinationId) async {
    if (currentUserId == null) return;

    try {
      await _currentUserDoc!.update({
        'favoriteDestinations': FieldValue.arrayRemove([destinationId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Check if destination is in favorites
  Future<bool> isFavorite(String destinationId) async {
    final favorites = await getUserFavorites();
    return favorites.contains(destinationId);
  }

  /// Get favorite destinations with full details
  Future<List<Destination>> getFavoriteDestinations() async {
    try {
      final favoriteIds = await getUserFavorites();
      if (favoriteIds.isEmpty) return [];

      final destinations = <Destination>[];

      // Firestore 'in' queries are limited to 10 items
      for (int i = 0; i < favoriteIds.length; i += 10) {
        final chunk = favoriteIds.skip(i).take(10).toList();
        final querySnapshot = await _destinationsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          if (doc.data() != null) {
            destinations.add(Destination.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }));
          }
        }
      }

      return destinations;
    } catch (e) {
      throw Exception('Failed to get favorite destinations: $e');
    }
  }

  // ==================== TRAVEL HISTORY ====================

  /// Add destination to travel history
  Future<void> addToTravelHistory(String destinationId, {String? notes}) async {
    if (currentUserId == null) return;

    try {
      final historyItem = {
        'destinationId': destinationId,
        'visitedAt': FieldValue.serverTimestamp(),
        'notes': notes,
      };

      await _currentUserDoc!.set({
        'travelHistory': FieldValue.arrayUnion([historyItem]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add to travel history: $e');
    }
  }

  /// Get user's travel history
  Future<List<Map<String, dynamic>>> getTravelHistory() async {
    if (currentUserId == null) return [];

    try {
      final doc = await _currentUserDoc!.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['travelHistory'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get travel history: $e');
    }
  }

  // ==================== RECOMMENDATIONS ====================

  /// Get personalized destination recommendations
  Future<List<Destination>> getRecommendations({int limit = 10}) async {
    try {
      // For now, get popular destinations
      // In the future, this could use user preferences and ML
      return getDestinations(limit: limit);
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  // ==================== ADMIN FUNCTIONS ====================

  /// Add a new destination (admin function)
  Future<String> addDestination(Destination destination) async {
    try {
      final docRef = await _destinationsCollection.add(destination.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add destination: $e');
    }
  }

  /// Update destination (admin function)
  Future<void> updateDestination(
      String destinationId, Map<String, dynamic> updates) async {
    try {
      await _destinationsCollection.doc(destinationId).update(updates);
    } catch (e) {
      throw Exception('Failed to update destination: $e');
    }
  }

  /// Delete destination (admin function)
  Future<void> deleteDestination(String destinationId) async {
    try {
      await _destinationsCollection.doc(destinationId).delete();
    } catch (e) {
      throw Exception('Failed to delete destination: $e');
    }
  }

  // ==================== STREAMS ====================

  /// Stream destinations
  Stream<List<Destination>> streamDestinations({int limit = 20}) {
    return _destinationsCollection
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Destination.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  /// Stream user favorites
  Stream<List<String>> streamUserFavorites() {
    if (currentUserId == null) return Stream.value([]);

    return _currentUserDoc!.snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['favoriteDestinations'] ?? []);
      }
      return <String>[];
    });
  }
}
