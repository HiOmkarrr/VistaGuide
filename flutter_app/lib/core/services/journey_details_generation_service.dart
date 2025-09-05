import 'package:flutter/foundation.dart';
import '../../features/journeys/data/models/journey.dart';
import '../../features/journeys/data/models/journey_details_data.dart';
import 'gemini_service.dart';

/// Service for generating journey-specific details using Gemini AI
/// Handles prompt creation, API calls, and response parsing for journey data
class JourneyDetailsGenerationService {
  final GeminiService _geminiService;
  
  JourneyDetailsGenerationService() : _geminiService = GeminiService();
  
  /// Generate journey details for a given journey using Gemini AI
  Future<JourneyDetailsData?> generateJourneyDetails(Journey journey) async {
    if (!_geminiService.isInitialized) {
      debugPrint('❌ Gemini service not initialized, using fallback data');
      return _getFallbackData();
    }
    
    try {
      debugPrint('🎯 Generating journey details for: ${journey.title}');
      
      final prompt = _createPrompt(journey);
      final response = await _geminiService.generateContent(prompt);
      
      if (response == null) {
        debugPrint('❌ Failed to get response from Gemini, using fallback data');
        return _getFallbackData();
      }
      
      final journeyDetails = _parseResponse(response);
      if (journeyDetails == null) {
        debugPrint('❌ Failed to parse Gemini response, using fallback data');
        return _getFallbackData();
      }
      
      debugPrint('✅ Successfully generated journey details');
      return journeyDetails;
      
    } catch (e) {
      debugPrint('❌ Error generating journey details: $e');
      return _getFallbackData();
    }
  }
  
  /// Create a structured prompt for Gemini AI
  String _createPrompt(Journey journey) {
    final destinations = journey.destinations.join(', ');
    final duration = journey.durationInDays;
    final startMonth = _getMonthName(journey.startDate.month);
    
    return '''
You are a knowledgeable travel planning assistant. Based on the provided trip information, generate practical travel advice in valid JSON format.

Trip Details:
- Title: ${journey.title}
- Description: ${journey.description}
- Destinations: $destinations
- Start Date: ${journey.startDate.day} $startMonth ${journey.startDate.year}
- Duration: $duration days
- Season: $startMonth

Important: Respond with ONLY a valid JSON object. No additional text, explanations, or markdown formatting.

Required JSON structure:
{
  "weather": {
    "type": "hot|cool|rainy|snowy",
    "temperature": "temperature range with unit",
    "bestTime": "best time of day to visit"
  },
  "whatToBring": [
    "specific practical items based on destination climate and activities",
    "altitude-specific items if applicable",
    "weather-appropriate clothing"
  ],
  "safetyNotes": [
    "location-specific safety advice",
    "cultural considerations",
    "common precautions"
  ],
  "emergencyContacts": {
    "medical": "local emergency medical number",
    "police": "local police number"
  },
  "placesEvents": [
    {
      "name": "specific place or event name",
      "type": "historical monument|cultural event|market|religious site|natural attraction|museum|festival|etc"
    }
  ],
  "packingChecklist": [
    "essential travel documents",
    "destination-specific items",
    "weather-appropriate clothing",
    "health and safety items"
  ]
}

Guidelines:
- For weather.type: Choose based on destination and season (hot/cool/rainy/snowy)
- For temperature: Provide realistic range (e.g., "15-25°C", "80-90°F")
- For emergency contacts: Use actual local emergency numbers for the destination country
- For places/events: Include 4-8 real, famous attractions/events for the destinations
- Keep all text concise and practical
- Focus on actionable, specific advice

Generate the JSON now:''';
  }
  
  /// Parse the Gemini response into JourneyDetailsData
  JourneyDetailsData? _parseResponse(Map<String, dynamic> response) {
    try {
      // Validate required fields
      if (!_validateResponseStructure(response)) {
        debugPrint('❌ Invalid response structure');
        return null;
      }
      
      // Parse weather data
      final weatherData = response['weather'] as Map<String, dynamic>;
      final weather = WeatherInfo(
        type: weatherData['type'] as String,
        temperature: weatherData['temperature'] as String,
        bestTime: weatherData['bestTime'] as String,
      );
      
      // Parse what to bring
      final whatToBring = (response['whatToBring'] as List)
          .map((item) => item.toString())
          .toList();
      
      // Parse safety notes
      final safetyNotes = (response['safetyNotes'] as List)
          .map((item) => item.toString())
          .toList();
      
      // Parse emergency contacts
      final contactsData = response['emergencyContacts'] as Map<String, dynamic>;
      final emergencyContacts = EmergencyContacts(
        medical: contactsData['medical'] as String,
        police: contactsData['police'] as String,
      );
      
      // Parse places and events
      final placesData = response['placesEvents'] as List;
      final placesEvents = placesData
          .map((item) {
            final itemMap = item as Map<String, dynamic>;
            return PlaceEvent(
              name: itemMap['name'] as String,
              type: itemMap['type'] as String,
            );
          })
          .toList();
      
      // Parse packing checklist
      final packingChecklist = (response['packingChecklist'] as List)
          .map((item) => item.toString())
          .toList();
      
      return JourneyDetailsData(
        weather: weather,
        whatToBring: whatToBring,
        safetyNotes: safetyNotes,
        emergencyContacts: emergencyContacts,
        placesEvents: placesEvents,
        packingChecklist: packingChecklist,
      );
      
    } catch (e) {
      debugPrint('❌ Error parsing Gemini response: $e');
      return null;
    }
  }
  
  /// Validate that the response has the expected structure
  bool _validateResponseStructure(Map<String, dynamic> response) {
    try {
      // Check required top-level fields
      final requiredFields = ['weather', 'whatToBring', 'safetyNotes', 
                             'emergencyContacts', 'placesEvents', 'packingChecklist'];
      
      for (final field in requiredFields) {
        if (!response.containsKey(field)) {
          debugPrint('❌ Missing required field: $field');
          return false;
        }
      }
      
      // Check weather structure
      final weather = response['weather'] as Map<String, dynamic>?;
      if (weather == null || !weather.containsKey('type') || 
          !weather.containsKey('temperature') || !weather.containsKey('bestTime')) {
        debugPrint('❌ Invalid weather structure');
        return false;
      }
      
      // Check emergency contacts structure
      final contacts = response['emergencyContacts'] as Map<String, dynamic>?;
      if (contacts == null || !contacts.containsKey('medical') || 
          !contacts.containsKey('police')) {
        debugPrint('❌ Invalid emergency contacts structure');
        return false;
      }
      
      // Check that arrays are actually arrays
      final arrayFields = ['whatToBring', 'safetyNotes', 'placesEvents', 'packingChecklist'];
      for (final field in arrayFields) {
        if (response[field] is! List) {
          debugPrint('❌ Field $field is not an array');
          return false;
        }
      }
      
      // Check places/events structure
      final places = response['placesEvents'] as List;
      for (final place in places) {
        if (place is! Map || !place.containsKey('name') || !place.containsKey('type')) {
          debugPrint('❌ Invalid place/event structure');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error validating response structure: $e');
      return false;
    }
  }
  
  /// Get fallback data when AI generation fails
  JourneyDetailsData _getFallbackData() {
    debugPrint('🔄 Using fallback journey details data');
    return dummyJourneyDetails;
  }
  
  /// Helper to get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  
  /// Check if the service is ready to generate content
  bool get isReady => _geminiService.isInitialized;
  
  /// Get service status for debugging
  String get serviceStatus {
    return 'Gemini API: ${_geminiService.apiKeyStatus}';
  }
}
