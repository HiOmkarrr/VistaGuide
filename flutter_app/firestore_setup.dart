import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

/// Standalone script to set up Firestore collections
void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('Setting up Firestore collections...');

  try {
    // 1. Create users collection with a placeholder document
    print('Creating users collection...');
    await firestore.collection('users').doc('_placeholder').set({
      'placeholder': true,
      'createdAt': FieldValue.serverTimestamp(),
      'description': 'This is a placeholder document to create the collection'
    });

    // 2. Create destinations collection with sample data
    print('Creating destinations collection...');
    final destinationsRef = firestore.collection('destinations');
    
    final sampleDestination = {
      'title': 'Sample Destination',
      'subtitle': 'A placeholder destination for testing',
      'description': 'This is a sample destination created for testing purposes.',
      'rating': 4.5,
      'tags': ['Sample', 'Test'],
      'imageUrls': ['https://via.placeholder.com/800x600'],
      'location': 'Test Location',
      'country': 'Test Country',
      'bestVisitTime': 'Year round',
      'averageCost': 100.0,
      'activities': ['Testing', 'Development'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await destinationsRef.add(sampleDestination);

    // 3. Create userData collection with placeholder
    print('Creating userData collection...');
    await firestore.collection('userData').doc('_placeholder').set({
      'placeholder': true,
      'createdAt': FieldValue.serverTimestamp(),
      'description': 'Placeholder for user-specific data like favorites and history'
    });

    // 4. Create travel_plans collection
    print('Creating travel_plans collection...');
    await firestore.collection('travel_plans').doc('_placeholder').set({
      'placeholder': true,
      'createdAt': FieldValue.serverTimestamp(),
      'description': 'Placeholder for user travel plans'
    });

    print('✅ Successfully created all Firestore collections!');
    print('Collections created:');
    print('  - users');
    print('  - destinations');
    print('  - userData');
    print('  - travel_plans');
    
  } catch (e) {
    print('❌ Error setting up Firestore collections: $e');
  }
}
