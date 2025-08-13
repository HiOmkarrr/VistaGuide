import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/home/data/models/destination.dart';

/// Service to populate Firestore with sample destination data
class FirestoreDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Populate Firestore with sample destinations for testing
  static Future<void> seedSampleDestinations() async {
    try {
      print('🌱 Seeding Firestore with sample destinations...');
      
      final sampleDestinations = _getSampleDestinations();
      final batch = _firestore.batch();
      
      for (final destination in sampleDestinations) {
        final docRef = _firestore.collection('destinations').doc(destination.id);
        batch.set(docRef, {
          ...destination.toJson(),
          'source': 'sample_data',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ Successfully seeded ${sampleDestinations.length} sample destinations');
      
    } catch (e) {
      print('❌ Error seeding sample destinations: $e');
    }
  }

  /// Check if destinations collection is empty and seed if needed
  static Future<void> seedIfEmpty() async {
    try {
      final snapshot = await _firestore.collection('destinations').limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        print('📍 No destinations found in Firestore, seeding sample data...');
        await seedSampleDestinations();
      } else {
        print('✅ Destinations collection already populated (${snapshot.docs.length} found)');
      }
    } catch (e) {
      print('❌ Error checking destinations collection: $e');
    }
  }

  /// Generate sample destinations for different locations
  static List<Destination> _getSampleDestinations() {
    return [
      // San Francisco Bay Area (near your test location 37.4219983, -122.084)
      Destination(
        id: 'golden_gate_bridge',
        title: 'Golden Gate Bridge',
        subtitle: 'Iconic suspension bridge in San Francisco',
        type: 'monument',
        coordinates: const GeoCoordinates(latitude: 37.8199, longitude: -122.4783),
        rating: 4.7,
        tags: ['landmark', 'photography', 'iconic'],
        historicalInfo: const HistoricalInfo(
          briefDescription: 'Built in 1937, this Art Deco suspension bridge connects San Francisco to Marin County.',
          extendedDescription: 'The Golden Gate Bridge was designed by engineer Joseph Strauss and architect Irving Morrow. Construction began in 1933 and was completed in 1937. At the time of its completion, it was the longest suspension bridge in the world.',
          keyEvents: ['Construction began 1933', 'Opened to pedestrians May 27, 1937', 'Opened to vehicles May 28, 1937'],
          relatedFigures: ['Joseph Strauss', 'Irving Morrow'],
        ),
        educationalInfo: const EducationalInfo(
          facts: [
            'Total length: 8,980 feet (2,737 m)',
            'Main span: 4,200 feet (1,280 m)',
            'Height: 746 feet (227 m)',
            'International Orange color for visibility in fog'
          ],
          importance: 'Engineering marvel and symbol of San Francisco',
          culturalRelevance: 'Featured in countless movies and artworks, symbol of American ingenuity',
          categories: ['architecture', 'engineering', 'transportation'],
        ),
        images: const [
          'https://example.com/golden_gate_1.jpg',
          'https://example.com/golden_gate_2.jpg'
        ],
        isOfflineAvailable: true,
      ),
      
      Destination(
        id: 'alcatraz_island',
        title: 'Alcatraz Island',
        subtitle: 'Historic federal prison on San Francisco Bay',
        type: 'museum',
        coordinates: const GeoCoordinates(latitude: 37.8267, longitude: -122.4230),
        rating: 4.5,
        tags: ['history', 'museum', 'prison', 'island'],
        historicalInfo: const HistoricalInfo(
          briefDescription: 'Former federal prison that housed infamous criminals from 1934 to 1963.',
          extendedDescription: 'Alcatraz served as a federal prison for 29 years, housing notorious inmates like Al Capone and Robert Stroud. Before becoming a prison, it was a military fortification and later a military prison.',
          keyEvents: ['Military fort 1850s', 'Federal prison 1934-1963', 'Native American occupation 1969-1971'],
          relatedFigures: ['Al Capone', 'Machine Gun Kelly', 'Robert Stroud'],
        ),
        educationalInfo: const EducationalInfo(
          facts: [
            'Housed 1,576 inmates over 29 years',
            'No confirmed successful escapes',
            'Famous 1962 escape attempt by Frank Morris and Anglin brothers',
            'Now part of Golden Gate National Recreation Area'
          ],
          importance: 'Symbol of American federal prison system',
          culturalRelevance: 'Subject of numerous books, movies, and documentaries',
          categories: ['history', 'criminal justice', 'architecture'],
        ),
        isOfflineAvailable: true,
      ),

      Destination(
        id: 'stanford_university',
        title: 'Stanford University',
        subtitle: 'Prestigious private research university',
        type: 'attraction',
        coordinates: const GeoCoordinates(latitude: 37.4275, longitude: -122.1697),
        rating: 4.6,
        tags: ['education', 'architecture', 'campus'],
        historicalInfo: const HistoricalInfo(
          briefDescription: 'Founded in 1885 by Leland and Jane Stanford in memory of their son.',
          extendedDescription: 'Stanford University was established as a memorial to Leland Stanford Jr., who died of typhoid fever at age 15. The university has become one of the world\'s leading research institutions.',
          keyEvents: ['Founded 1885', 'First classes 1891', 'Became coeducational 1891'],
          relatedFigures: ['Leland Stanford', 'Jane Stanford', 'David Starr Jordan'],
        ),
        educationalInfo: const EducationalInfo(
          facts: [
            'Campus covers 8,180 acres',
            'Home to Stanford Research Park',
            'Has produced numerous Nobel Prize winners',
            'Birthplace of many Silicon Valley companies'
          ],
          importance: 'Leading research university and Silicon Valley pioneer',
          culturalRelevance: 'Center of innovation and technology development',
          categories: ['education', 'research', 'technology'],
        ),
        isOfflineAvailable: true,
      ),

      Destination(
        id: 'muir_woods',
        title: 'Muir Woods National Monument',
        subtitle: 'Ancient coastal redwood forest',
        type: 'park',
        coordinates: const GeoCoordinates(latitude: 37.8955, longitude: -122.5808),
        rating: 4.4,
        tags: ['nature', 'redwoods', 'hiking', 'conservation'],
        historicalInfo: const HistoricalInfo(
          briefDescription: 'Protected redwood forest named after naturalist John Muir.',
          extendedDescription: 'Established in 1908 as a National Monument, Muir Woods preserves one of the last old-growth coastal redwood forests in the Bay Area. The trees here are 600-800 years old.',
          keyEvents: ['Established as National Monument 1908', 'Named after John Muir', 'Designated UNESCO site 1987'],
          relatedFigures: ['John Muir', 'William Kent', 'Theodore Roosevelt'],
        ),
        educationalInfo: const EducationalInfo(
          facts: [
            'Trees can live over 2,000 years',
            'Some trees over 250 feet tall',
            'Contains 6 miles of walking trails',
            'Home to diverse wildlife including deer and birds'
          ],
          importance: 'Conservation of ancient forest ecosystem',
          culturalRelevance: 'Inspiration for environmental protection movement',
          categories: ['nature', 'conservation', 'ecology'],
        ),
        isOfflineAvailable: true,
      ),

      Destination(
        id: 'lombard_street',
        title: 'Lombard Street',
        subtitle: 'The "Crookedest Street in the World"',
        type: 'attraction',
        coordinates: const GeoCoordinates(latitude: 37.8021, longitude: -122.4187),
        rating: 4.2,
        tags: ['street', 'photography', 'unique', 'scenic'],
        historicalInfo: const HistoricalInfo(
          briefDescription: 'Famous winding street with eight sharp turns, created in the 1920s.',
          extendedDescription: 'The curvy section of Lombard Street was designed in 1922 to reduce the hill\'s natural 27% grade, making it safer for vehicles to navigate.',
          keyEvents: ['Street design created 1922', 'Became tourist attraction 1960s'],
        ),
        educationalInfo: const EducationalInfo(
          facts: [
            'Contains 8 hairpin turns',
            'Speed limit is 5 mph',
            'Lined with hydrangea bushes',
            'Attracts over 2 million visitors annually'
          ],
          importance: 'Unique urban engineering solution',
          culturalRelevance: 'Symbol of San Francisco\'s hilly topography',
          categories: ['urban planning', 'architecture', 'tourism'],
        ),
        isOfflineAvailable: true,
      ),
    ];
  }
}
