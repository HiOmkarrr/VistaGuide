import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to initialize sample data in Firestore
class DataInitializationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize sample destinations in Firestore
  Future<void> initializeSampleDestinations() async {
    try {
      final destinationsCollection = _firestore.collection('destinations');

      // Check if destinations already exist
      final existingDestinations = await destinationsCollection.limit(1).get();
      if (existingDestinations.docs.isNotEmpty) {
        // print('Sample destinations already exist');
        return;
      }

      // Sample destinations data
      final sampleDestinations = [
        {
          'title': 'The Alps',
          'subtitle':
              'Explore the majestic peaks and charming villages of the Alps.',
          'description':
              'The Alps stretch across eight countries and offer breathtaking views, world-class skiing, and charming mountain villages. Experience the perfect blend of adventure and tranquility.',
          'rating': 4.8,
          'tags': ['Mountains', 'Adventure', 'Nature', 'Skiing', 'Hiking'],
          'imageUrls': [
            'https://images.unsplash.com/photo-1551524164-6cf1ae83e4bf?w=800',
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
          ],
          'location': 'European Alps',
          'country': 'Multi-country',
          'bestVisitTime':
              'June to September (Summer), December to March (Winter)',
          'averageCost': 150.0,
          'activities': ['Skiing', 'Hiking', 'Mountaineering', 'Photography'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Maldives',
          'subtitle': 'Relax on pristine beaches with vibrant coral reefs.',
          'description':
              'The Maldives is a tropical paradise with crystal-clear waters, pristine white sand beaches, and luxury overwater bungalows. Perfect for honeymoons and relaxation.',
          'rating': 4.9,
          'tags': ['Beach', 'Relaxation', 'Tropical', 'Diving', 'Luxury'],
          'imageUrls': [
            'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?w=800',
            'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=800',
          ],
          'location': 'Indian Ocean',
          'country': 'Maldives',
          'bestVisitTime': 'November to April',
          'averageCost': 300.0,
          'activities': [
            'Diving',
            'Snorkeling',
            'Water Sports',
            'Spa Treatments'
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Tokyo',
          'subtitle': 'Discover the blend of tradition and modernity.',
          'description':
              'Tokyo is a vibrant metropolis where ancient traditions meet cutting-edge technology. Explore temples, taste incredible cuisine, and experience the bustling city life.',
          'rating': 4.7,
          'tags': ['City', 'Culture', 'Food', 'Technology', 'Shopping'],
          'imageUrls': [
            'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
            'https://images.unsplash.com/photo-1513407030348-c983a97b98d8?w=800',
          ],
          'location': 'Kanto Region',
          'country': 'Japan',
          'bestVisitTime': 'March to May, September to November',
          'averageCost': 120.0,
          'activities': [
            'Temple Visits',
            'Food Tours',
            'Shopping',
            'Nightlife'
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Santorini',
          'subtitle':
              'Experience stunning sunsets and white-washed architecture.',
          'description':
              'Santorini is famous for its dramatic cliffs, beautiful sunsets, and distinctive white and blue architecture. A perfect romantic getaway in the Greek islands.',
          'rating': 4.6,
          'tags': ['Islands', 'Romance', 'Architecture', 'Wine', 'Sunset'],
          'imageUrls': [
            'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800',
            'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800',
          ],
          'location': 'Cyclades',
          'country': 'Greece',
          'bestVisitTime': 'April to November',
          'averageCost': 180.0,
          'activities': [
            'Wine Tasting',
            'Sunset Viewing',
            'Beach Relaxation',
            'Photography'
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Machu Picchu',
          'subtitle': 'Explore the ancient Incan citadel in the clouds.',
          'description':
              'Machu Picchu is one of the New Seven Wonders of the World, offering incredible history, stunning mountain views, and an unforgettable hiking experience.',
          'rating': 4.8,
          'tags': ['History', 'Adventure', 'Mountains', 'UNESCO', 'Hiking'],
          'imageUrls': [
            'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=800',
            'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=800',
          ],
          'location': 'Cusco Region',
          'country': 'Peru',
          'bestVisitTime': 'May to September',
          'averageCost': 200.0,
          'activities': [
            'Hiking',
            'Historical Tours',
            'Photography',
            'Cultural Experiences'
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Safari in Kenya',
          'subtitle': 'Witness the Great Migration and Big Five animals.',
          'description':
              'Experience the thrill of African wildlife in their natural habitat. Kenya offers incredible safari experiences with diverse ecosystems and abundant wildlife.',
          'rating': 4.7,
          'tags': ['Wildlife', 'Safari', 'Adventure', 'Nature', 'Photography'],
          'imageUrls': [
            'https://images.unsplash.com/photo-1549366021-9f761d040a94?w=800',
            'https://images.unsplash.com/photo-1551632436-cbf8dd35adfa?w=800',
          ],
          'location': 'East Africa',
          'country': 'Kenya',
          'bestVisitTime': 'July to October, January to March',
          'averageCost': 250.0,
          'activities': [
            'Game Drives',
            'Wildlife Photography',
            'Cultural Visits',
            'Hot Air Balloon'
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Bali',
          'subtitle': 'Discover temples, rice terraces, and tropical beaches.',
          'description':
              'Bali offers a perfect mix of culture, nature, and relaxation. Explore ancient temples, stunning rice terraces, beautiful beaches, and vibrant local culture.',
          'rating': 4.5,
          'tags': ['Beach', 'Culture', 'Temples', 'Rice Terraces', 'Yoga'],
          'imageUrls': [
            'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=800',
            'https://images.unsplash.com/photo-1537953773345-d172ccf13cf1?w=800',
          ],
          'location': 'Indonesian Archipelago',
          'country': 'Indonesia',
          'bestVisitTime': 'April to October',
          'averageCost': 80.0,
          'activities': [
            'Temple Visits',
            'Yoga Retreats',
            'Surfing',
            'Cultural Tours'
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Northern Lights in Iceland',
          'subtitle': 'Chase the aurora borealis in dramatic landscapes.',
          'description':
              'Iceland offers the perfect opportunity to witness the Northern Lights while exploring dramatic landscapes including geysers, waterfalls, and glaciers.',
          'rating': 4.6,
          'tags': [
            'Northern Lights',
            'Nature',
            'Adventure',
            'Photography',
            'Glaciers'
          ],
          'imageUrls': [
            'https://images.unsplash.com/photo-1539066584654-769dda8ba50c?w=800',
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
          ],
          'location': 'North Atlantic',
          'country': 'Iceland',
          'bestVisitTime': 'September to March',
          'averageCost': 220.0,
          'activities': [
            'Aurora Hunting',
            'Glacier Tours',
            'Hot Springs',
            'Whale Watching'
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add each destination to Firestore
      for (final destination in sampleDestinations) {
        await destinationsCollection.add(destination);
      }

      // print(
      //     'Successfully initialized ${sampleDestinations.length} sample destinations');
    } catch (e) {
      // print('Error initializing sample destinations: $e');
      throw Exception('Failed to initialize sample data: $e');
    }
  }

  /// Initialize Firestore security rules (development only)
  void printFirestoreRules() {
//     print('''
// Firestore Security Rules for VistaGuide (Development):

// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
//     // Users can read and write their own user data
//     match /users/{userId} {
//       allow read, write: if request.auth != null && request.auth.uid == userId;
//     }
    
//     // All authenticated users can read destinations
//     match /destinations/{destinationId} {
//       allow read: if request.auth != null;
//       allow write: if request.auth != null && hasAdminRole();
//     }
    
//     // Users can read and write their own user data
//     match /userData/{userId} {
//       allow read, write: if request.auth != null && request.auth.uid == userId;
//     }
    
//     // Function to check admin role (implement based on your needs)
//     function hasAdminRole() {
//       return request.auth.token.admin == true;
//     }
//   }
// }

// Add these rules to your Firestore console for development.
// For production, implement more specific rules based on your requirements.
//     ''');
  }
}
