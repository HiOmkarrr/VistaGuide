/// Data models for simplified journey details tabs

class WeatherInfo {
  final String type; // "hot", "cool", "rainy", "snowy"
  final String temperature; // "15-25°C"
  final String bestTime; // "Morning and evening"

  const WeatherInfo({
    required this.type,
    required this.temperature,
    required this.bestTime,
  });
}

class EmergencyContacts {
  final String medical;
  final String police;

  const EmergencyContacts({
    required this.medical,
    required this.police,
  });
}

class PlaceEvent {
  final String name;
  final String type;
  final bool isUnderrated;
  final String? description;
  final String? location;
  final int? underratedScore;
  final String? estimatedCost;

  const PlaceEvent({
    required this.name,
    required this.type,
    this.isUnderrated = false,
    this.description,
    this.location,
    this.underratedScore,
    this.estimatedCost,
  });

  /// Create a regular place event (from Gemini)
  factory PlaceEvent.regular({
    required String name,
    required String type,
  }) {
    return PlaceEvent(
      name: name,
      type: type,
      isUnderrated: false,
    );
  }

  /// Create an underrated place event (from CSV)
  factory PlaceEvent.underrated({
    required String name,
    required String type,
    required String description,
    required String location,
    required int underratedScore,
    String? estimatedCost,
  }) {
    return PlaceEvent(
      name: name,
      type: type,
      isUnderrated: true,
      description: description,
      location: location,
      underratedScore: underratedScore,
      estimatedCost: estimatedCost,
    );
  }
}

class JourneyDetailsData {
  // Safety & Weather Tab
  final WeatherInfo weather;
  final List<String> whatToBring;
  final List<String> safetyNotes;
  final EmergencyContacts emergencyContacts;
  
  // Suggestions & Events Tab
  final List<PlaceEvent> placesEvents;
  final List<String> packingChecklist;

  const JourneyDetailsData({
    required this.weather,
    required this.whatToBring,
    required this.safetyNotes,
    required this.emergencyContacts,
    required this.placesEvents,
    required this.packingChecklist,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'weather': {
        'type': weather.type,
        'temperature': weather.temperature,
        'bestTime': weather.bestTime,
      },
      'whatToBring': whatToBring,
      'safetyNotes': safetyNotes,
      'emergencyContacts': {
        'medical': emergencyContacts.medical,
        'police': emergencyContacts.police,
      },
      'placesEvents': placesEvents.map((place) => {
        'name': place.name,
        'type': place.type,
        'isUnderrated': place.isUnderrated,
        'description': place.description,
        'location': place.location,
        'underratedScore': place.underratedScore,
        'estimatedCost': place.estimatedCost,
      }).toList(),
      'packingChecklist': packingChecklist,
    };
  }

  /// Create from JSON
  factory JourneyDetailsData.fromJson(Map<String, dynamic> json) {
    return JourneyDetailsData(
      weather: WeatherInfo(
        type: json['weather']['type'] as String,
        temperature: json['weather']['temperature'] as String,
        bestTime: json['weather']['bestTime'] as String,
      ),
      whatToBring: (json['whatToBring'] as List<dynamic>).cast<String>(),
      safetyNotes: (json['safetyNotes'] as List<dynamic>).cast<String>(),
      emergencyContacts: EmergencyContacts(
        medical: json['emergencyContacts']['medical'] as String,
        police: json['emergencyContacts']['police'] as String,
      ),
      placesEvents: (json['placesEvents'] as List<dynamic>)
          .map((item) => PlaceEvent(
                name: item['name'] as String,
                type: item['type'] as String,
                isUnderrated: item['isUnderrated'] as bool? ?? false,
                description: item['description'] as String?,
                location: item['location'] as String?,
                underratedScore: item['underratedScore'] as int?,
                estimatedCost: item['estimatedCost'] as String?,
              ))
          .toList(),
      packingChecklist: (json['packingChecklist'] as List<dynamic>).cast<String>(),
    );
  }

  /// Convert to database map (for SQLite)
  Map<String, dynamic> toMap(String journeyId) {
    return {
      'journey_id': journeyId,
      'weather_type': weather.type,
      'weather_temperature': weather.temperature,
      'weather_best_time': weather.bestTime,
      'what_to_bring': whatToBring.join('|'), // Use pipe separator
      'safety_notes': safetyNotes.join('|'),
      'emergency_medical': emergencyContacts.medical,
      'emergency_police': emergencyContacts.police,
      'places_events': placesEvents.map((p) => '${p.name}~~${p.type}~~${p.isUnderrated}~~${p.description ?? ''}~~${p.location ?? ''}~~${p.underratedScore ?? ''}~~${p.estimatedCost ?? ''}').join('|'), // Use ~~ as field separator
      'packing_checklist': packingChecklist.join('|'),
    };
  }

  /// Create from database map (for SQLite)
  factory JourneyDetailsData.fromMap(Map<String, dynamic> map) {
    return JourneyDetailsData(
      weather: WeatherInfo(
        type: map['weather_type'] as String,
        temperature: map['weather_temperature'] as String,
        bestTime: map['weather_best_time'] as String,
      ),
      whatToBring: (map['what_to_bring'] as String).isEmpty 
          ? <String>[] 
          : (map['what_to_bring'] as String).split('|'),
      safetyNotes: (map['safety_notes'] as String).isEmpty 
          ? <String>[] 
          : (map['safety_notes'] as String).split('|'),
      emergencyContacts: EmergencyContacts(
        medical: map['emergency_medical'] as String,
        police: map['emergency_police'] as String,
      ),
      placesEvents: (map['places_events'] as String).isEmpty 
          ? <PlaceEvent>[] 
          : (map['places_events'] as String).split('|').map((item) {
              final parts = item.split('~~');
              return PlaceEvent(
                name: parts.isNotEmpty ? parts[0] : '',
                type: parts.length > 1 ? parts[1] : '',
                isUnderrated: parts.length > 2 ? parts[2] == 'true' : false,
                description: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
                location: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
                underratedScore: parts.length > 5 && parts[5].isNotEmpty ? int.tryParse(parts[5]) : null,
                estimatedCost: parts.length > 6 && parts[6].isNotEmpty ? parts[6] : null,
              );
            }).toList(),
      packingChecklist: (map['packing_checklist'] as String).isEmpty 
          ? <String>[] 
          : (map['packing_checklist'] as String).split('|'),
    );
  }
}

// Dummy data for UI
const dummyJourneyDetails = JourneyDetailsData(
  weather: WeatherInfo(
    type: "cool",
    temperature: "15-25°C",
    bestTime: "Morning and evening"
  ),
  whatToBring: [
    "Camphor tablets for altitude",
    "Warm jacket for evenings", 
    "Sunscreen for day time",
    "Comfortable walking shoes"
  ],
  safetyNotes: [
    "Keep valuables secure",
    "Avoid Old Town after 10pm",
    "Don't drink tap water",
    "Stay in well-lit areas at night"
  ],
  emergencyContacts: EmergencyContacts(
    medical: "108",
    police: "100"
  ),
  placesEvents: [
    PlaceEvent(name: "Red Fort", type: "historical monument"),
    PlaceEvent(name: "Diwali Festival", type: "cultural event"),
    PlaceEvent(name: "Chandni Chowk", type: "traditional market"),
    PlaceEvent(name: "India Gate", type: "landmark"),
    PlaceEvent(name: "Lotus Temple", type: "religious site"),
    PlaceEvent(name: "Street Food Tour", type: "culinary experience")
  ],
  packingChecklist: [
    "Passport",
    "Travel insurance", 
    "Phone charger",
    "First aid kit",
    "Cash in local currency",
    "Comfortable shoes",
    "Weather-appropriate clothing",
    "Camera or phone"
  ]
);
