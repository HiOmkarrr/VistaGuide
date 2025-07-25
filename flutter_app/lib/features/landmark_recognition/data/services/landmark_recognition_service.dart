import '../models/landmark_recognition.dart';

/// Service to manage landmark recognition functionality
class LandmarkRecognitionService {
  static final LandmarkRecognitionService _instance =
      LandmarkRecognitionService._internal();
  factory LandmarkRecognitionService() => _instance;
  LandmarkRecognitionService._internal();

  // Mock data - in a real app, this would come from a database or API
  final List<LandmarkRecognition> _recentRecognitions = [
    LandmarkRecognition(
      id: '1',
      landmarkName: 'Eiffel Tower',
      description: 'Iconic iron lattice tower in Paris, France',
      confidence: 0.95,
      recognizedAt: DateTime.now().subtract(const Duration(hours: 2)),
      location: 'Paris, France',
      tags: ['Architecture', 'Historic', 'Tourist Attraction'],
    ),
    LandmarkRecognition(
      id: '2',
      landmarkName: 'Statue of Liberty',
      description: 'Symbol of freedom and democracy in New York Harbor',
      confidence: 0.88,
      recognizedAt: DateTime.now().subtract(const Duration(days: 1)),
      location: 'New York, USA',
      tags: ['Monument', 'Historic', 'Symbol'],
    ),
    LandmarkRecognition(
      id: '3',
      landmarkName: 'Big Ben',
      description: 'Famous clock tower in London, England',
      confidence: 0.92,
      recognizedAt: DateTime.now().subtract(const Duration(days: 3)),
      location: 'London, England',
      tags: ['Architecture', 'Clock Tower', 'Historic'],
    ),
  ];

  /// Get recent landmark recognitions
  List<LandmarkRecognition> getRecentRecognitions() {
    return List.unmodifiable(_recentRecognitions);
  }

  /// Get instructions text
  String getInstructionsTitle() {
    return 'Capture or upload a photo to identify landmarks.';
  }

  /// Get instructions subtitle
  String getInstructionsSubtitle() {
    return 'Point your camera at a landmark or select from your gallery.';
  }

  /// Handle image source selection
  Future<void> showImageSourceDialog() async {
    // In a real implementation, this would show a dialog to choose between camera and gallery
    print('Showing image source dialog');
    // TODO: Implement image picker functionality
  }

  /// Process image for landmark recognition
  Future<LandmarkRecognition?> recognizeLandmark(String imagePath) async {
    // In a real implementation, this would:
    // 1. Send image to ML service
    // 2. Process recognition results
    // 3. Save to recent recognitions
    // 4. Return recognition result

    print('Processing image: $imagePath');
    // TODO: Implement actual landmark recognition
    return null;
  }

  /// Add a new recognition to recent list
  void addRecognition(LandmarkRecognition recognition) {
    _recentRecognitions.insert(0, recognition);
    // Keep only the most recent 10 recognitions
    if (_recentRecognitions.length > 10) {
      _recentRecognitions.removeRange(10, _recentRecognitions.length);
    }
  }

  /// Clear all recent recognitions
  void clearRecentRecognitions() {
    _recentRecognitions.clear();
  }

  /// Get recognition by ID
  LandmarkRecognition? getRecognitionById(String id) {
    try {
      return _recentRecognitions
          .firstWhere((recognition) => recognition.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Handle recognition tap
  void handleRecognitionTap(String recognitionId) {
    final recognition = getRecognitionById(recognitionId);
    if (recognition != null) {
      print('Tapped recognition: ${recognition.landmarkName}');
      // TODO: Navigate to recognition details or show more info
    }
  }
}
