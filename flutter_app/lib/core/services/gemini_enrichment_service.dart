import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/home/data/models/destination.dart';

/// Service to enrich destination data using Google Gemini API
class GeminiEnrichmentService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Check if Gemini API is configured
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Enrich destination with historical and educational information using Gemini
  static Future<Destination> enrichDestination(Destination destination) async {
    if (!isConfigured) {
      print('⚠️ Gemini API not configured, skipping enrichment');
      return destination;
    }

    try {
      print('🤖 Enriching destination: ${destination.title}');

      // Create instance to call non-static method
      final service = GeminiEnrichmentService();
      final enrichedData = await service._getEnrichedInformation(
          destination.title, destination.type);

      if (enrichedData != null) {
        // Create enhanced historical info
        final enhancedHistorical = _createEnhancedHistoricalInfo(
            destination.historicalInfo, enrichedData['historical']);

        // Create enhanced educational info
        final enhancedEducational = _createEnhancedEducationalInfo(
            destination.educationalInfo, enrichedData['educational']);

        // Get image URL if available
        final imageUrl = await _getPlaceImageUrl(destination.title);

        return destination.copyWith(
          historicalInfo: enhancedHistorical,
          educationalInfo: enhancedEducational,
          imageUrl: imageUrl ?? destination.imageUrl,
          description: enrichedData['description'] ?? destination.description,
        );
      }

      return destination;
    } catch (e) {
      print('❌ Error enriching destination with Gemini: $e');
      return destination;
    }
  }

  /// Public method to enrich place information using Gemini AI
  Future<Map<String, dynamic>?> enrichPlaceInformation(String placeName) async {
    try {
      print('🤖 Enriching place information for: $placeName');

      // Determine place type (this could be made smarter with additional context)
      final placeType = _determinePlaceType(placeName);

      final enrichedData = await _getEnrichedInformation(placeName, placeType);

      if (enrichedData != null) {
        print('✅ Successfully enriched $placeName with Gemini AI');
        return enrichedData;
      }

      return null;
    } catch (e) {
      print('❌ Error enriching place information: $e');
      return null;
    }
  }

  /// Determine place type based on name patterns (basic implementation)
  String _determinePlaceType(String placeName) {
    final lowerName = placeName.toLowerCase();

    if (lowerName.contains('fort') || lowerName.contains('palace')) {
      return 'historical fort/palace';
    } else if (lowerName.contains('temple') ||
        lowerName.contains('mosque') ||
        lowerName.contains('church') ||
        lowerName.contains('cathedral')) {
      return 'religious site';
    } else if (lowerName.contains('museum')) {
      return 'museum';
    } else if (lowerName.contains('park') || lowerName.contains('garden')) {
      return 'park/garden';
    } else if (lowerName.contains('tower') || lowerName.contains('building')) {
      return 'architectural landmark';
    } else {
      return 'tourist attraction';
    }
  }

  /// Get enriched information from Gemini API
  Future<Map<String, dynamic>?> _getEnrichedInformation(
      String placeName, String placeType) async {
    try {
      final prompt = '''
Please provide comprehensive information about "$placeName" (a $placeType) in JSON format:

{
  "description": "Brief 2-3 sentence description",
  "historical": {
    "briefDescription": "2-3 sentence historical overview", 
    "extendedDescription": "Detailed 4-5 sentence historical background",
    "keyEvents": ["Event 1 with year", "Event 2 with year", "Event 3 with year"],
    "relatedFigures": ["Important person 1", "Important person 2"]
  },
  "educational": {
    "facts": ["Interesting fact 1", "Interesting fact 2", "Interesting fact 3"],
    "importance": "Why this place is culturally/historically significant",
    "culturalRelevance": "Cultural and social importance",
    "categories": ["category1", "category2"]
  },
  "imageKeywords": ["keyword1", "keyword2", "keyword3"]
}

Focus on:
- Historical accuracy
- Educational value  
- Cultural significance
- Interesting facts tourists would enjoy
- Keep descriptions concise but informative
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];

        // Extract JSON from the response
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonString = content.substring(jsonStart, jsonEnd);
          return jsonDecode(jsonString);
        }
      } else {
        print('❌ Gemini API error: ${response.statusCode} - ${response.body}');
      }

      return null;
    } catch (e) {
      print('❌ Error calling Gemini API: $e');
      return null;
    }
  }

  /// Get image URL for a place using Google Custom Search
  static Future<String?> _getPlaceImageUrl(String placeName) async {
    try {
      final searchApiKey = dotenv.env['GOOGLE_SEARCH_API_KEY'] ?? '';
      final searchEngineId = dotenv.env['GOOGLE_SEARCH_ENGINE_ID'] ?? '';

      if (searchApiKey.isEmpty || searchEngineId.isEmpty) {
        print('⚠️ Google Image Search not configured');
        return null;
      }

      final query =
          Uri.encodeComponent('$placeName landmark tourist attraction');
      final url =
          'https://www.googleapis.com/customsearch/v1?key=$searchApiKey&cx=$searchEngineId&q=$query&searchType=image&num=1&imgSize=large&imgType=photo';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List?;

        if (items != null && items.isNotEmpty) {
          return items[0]['link'] as String?;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting image URL: $e');
      return null;
    }
  }

  /// Create enhanced historical info by merging existing and Gemini data
  static HistoricalInfo? _createEnhancedHistoricalInfo(
      HistoricalInfo? existing, Map<String, dynamic>? geminiData) {
    if (geminiData == null) return existing;

    try {
      return HistoricalInfo(
        briefDescription:
            geminiData['briefDescription'] ?? existing?.briefDescription ?? '',
        extendedDescription: geminiData['extendedDescription'] ??
            existing?.extendedDescription ??
            '',
        keyEvents: [
          ...(existing?.keyEvents ?? []),
          ...(geminiData['keyEvents'] as List? ?? []).cast<String>(),
        ].toSet().cast<String>().toList(), // Remove duplicates
        relatedFigures: [
          ...(existing?.relatedFigures ?? []),
          ...(geminiData['relatedFigures'] as List? ?? []).cast<String>(),
        ].toSet().cast<String>().toList(), // Remove duplicates
      );
    } catch (e) {
      print('❌ Error creating enhanced historical info: $e');
      return existing;
    }
  }

  /// Create enhanced educational info by merging existing and Gemini data
  static EducationalInfo? _createEnhancedEducationalInfo(
      EducationalInfo? existing, Map<String, dynamic>? geminiData) {
    if (geminiData == null) return existing;

    try {
      return EducationalInfo(
        facts: [
          ...(existing?.facts ?? []),
          ...(geminiData['facts'] as List? ?? []).cast<String>(),
        ].toSet().cast<String>().toList(), // Remove duplicates
        importance: geminiData['importance'] ?? existing?.importance ?? '',
        culturalRelevance: geminiData['culturalRelevance'] ??
            existing?.culturalRelevance ??
            '',
        categories: [
          ...(existing?.categories ?? []),
          ...(geminiData['categories'] as List? ?? []).cast<String>(),
        ].toSet().cast<String>().toList(), // Remove duplicates
      );
    } catch (e) {
      print('❌ Error creating enhanced educational info: $e');
      return existing;
    }
  }

  /// Batch enrich multiple destinations
  static Future<List<Destination>> enrichDestinations(
      List<Destination> destinations) async {
    if (!isConfigured) {
      print('⚠️ Gemini API not configured, skipping batch enrichment');
      return destinations;
    }

    final enrichedDestinations = <Destination>[];

    for (final destination in destinations) {
      try {
        final enriched = await enrichDestination(destination);
        enrichedDestinations.add(enriched);

        // Add small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('❌ Error enriching destination ${destination.title}: $e');
        enrichedDestinations
            .add(destination); // Add original if enrichment fails
      }
    }

    return enrichedDestinations;
  }

  /// Initialize Gemini service
  static void initialize() {
    if (isConfigured) {
      print('✅ Gemini Enrichment Service initialized');
    } else {
      print('⚠️ Gemini API key not found in .env file');
      print(
          '💡 Add GEMINI_API_KEY=your_key_here to .env for enhanced features');
    }
  }
}
