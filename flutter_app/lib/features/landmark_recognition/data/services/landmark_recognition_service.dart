import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/landmark_recognition.dart';
import 'tensorflow_lite_service.dart';

/// Service to manage landmark recognition functionality
class LandmarkRecognitionService {
  static final LandmarkRecognitionService _instance =
      LandmarkRecognitionService._internal();
  factory LandmarkRecognitionService() => _instance;
  LandmarkRecognitionService._internal();

  final TensorFlowLiteService _tfLiteService = TensorFlowLiteService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isModelInitialized = false;

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

  /// Initialize the TensorFlow Lite model
  Future<bool> initializeModel() async {
    if (_isModelInitialized) return true;

    try {
      if (kDebugMode) {
        print('🔄 Initializing landmark recognition model...');
      }

      final success = await _tfLiteService.initializeModel();
      _isModelInitialized = success;

      if (success) {
        if (kDebugMode) {
          print('✅ Landmark recognition model initialized');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to initialize landmark recognition model');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing landmark recognition: $e');
      }
      return false;
    }
  }

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
  Future<void> showImageSourceDialog(BuildContext context) async {
    if (kDebugMode) {
      print('📱 Camera button pressed - showing image source dialog');
    }

    // Ensure model is initialized
    if (!_isModelInitialized) {
      if (kDebugMode) {
        print('🔄 Model not initialized, initializing now...');
      }
      await initializeModel();
    }

    if (kDebugMode) {
      print('🎯 Model status: ${_isModelInitialized ? "Ready" : "Failed"}');
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text(
              'Choose how you want to select an image for landmark recognition:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Camera'),
              onPressed: () {
                if (kDebugMode) {
                  print('📷 User selected Camera option');
                }
                Navigator.of(context).pop();
                _pickImageFromCamera(context);
              },
            ),
            TextButton(
              child: const Text('Gallery'),
              onPressed: () {
                if (kDebugMode) {
                  print('🖼️ User selected Gallery option');
                }
                Navigator.of(context).pop();
                _pickImageFromGallery(context);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera(BuildContext context) async {
    if (kDebugMode) {
      print('📸 Starting camera image capture...');
    }

    try {
      if (kDebugMode) {
        print('🔧 Calling ImagePicker.pickImage() with camera source...');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (kDebugMode) {
        print('📱 Camera picker result: ${image != null ? "Image captured: ${image.path}" : "No image captured (cancelled?)"}');
      }

      if (image != null) {
        if (kDebugMode) {
          print('✅ Image captured successfully, processing...');
        }
        // Check if context is still mounted before proceeding
        if (context.mounted) {
          await _processSelectedImage(context, File(image.path));
        } else {
          if (kDebugMode) {
            print('⚠️ Context not mounted, using context-free processing');
          }
          // Use context-free processing
          await processImageWithoutUI(image.path);
        }
      } else {
        if (kDebugMode) {
          print('❌ No image captured - user cancelled or error occurred');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image from camera: $e');
      }
      // Only show snackbar if context is safe to use
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Failed to capture image from camera');
        }
      });
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery(BuildContext context) async {
    if (kDebugMode) {
      print('🖼️ Starting gallery image picker...');
    }

    try {
      if (kDebugMode) {
        print('🔧 Calling ImagePicker.pickImage() with gallery source...');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (kDebugMode) {
        print('📱 Gallery picker result: ${image != null ? "Image selected: ${image.path}" : "No image selected (cancelled?)"}');
      }

      if (image != null) {
        if (kDebugMode) {
          print('✅ Image selected successfully, processing...');
        }
        // Check if context is still mounted before proceeding
        if (context.mounted) {
          await _processSelectedImage(context, File(image.path));
        } else {
          if (kDebugMode) {
            print('⚠️ Context not mounted, using context-free processing');
          }
          // Use context-free processing
          await processImageWithoutUI(image.path);
        }
      } else {
        if (kDebugMode) {
          print('❌ No image selected - user cancelled or error occurred');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image from gallery: $e');
      }
      // Only show snackbar if context is safe to use
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Failed to select image from gallery');
        }
      });
    }
  }

  /// Process the selected image
  Future<void> _processSelectedImage(
      BuildContext context, File imageFile) async {
    // Check if context is still mounted before showing dialog
    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Recognizing landmark...'),
          ],
        ),
      ),
    );

    try {
      if (kDebugMode) {
        print('📸 Starting image processing for: ${imageFile.path}');
      }

      // Recognize landmark using TensorFlow Lite
      final prediction = await recognizeLandmark(imageFile.path);

      if (kDebugMode) {
        print('🔮 Recognition completed. Result: ${prediction?.landmarkName ?? 'null'}');
      }

      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (prediction != null) {
        if (kDebugMode) {
          print('✅ Showing results for: ${prediction.landmarkName}');
        }
        // Show results dialog
        if (context.mounted) {
          _showRecognitionResults(context, prediction);
        }
      } else {
        if (kDebugMode) {
          print('❌ No prediction result, showing error');
        }
        if (context.mounted) {
          _showErrorSnackBar(
              context, 'Could not recognize landmark in this image');
        }
      }
    } catch (e) {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (kDebugMode) {
        print('❌ Error processing image: $e');
      }

      if (context.mounted) {
        _showErrorSnackBar(context, 'Error processing image');
      }
    }
  }

  /// Show recognition results
  void _showRecognitionResults(
      BuildContext context, LandmarkRecognition recognition) {
    // Check if context is still mounted before showing dialog
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🏛️ ${recognition.landmarkName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence: ${(recognition.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(recognition.description ?? 'No description available'),
            if (recognition.location != null &&
                recognition.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('📍 ${recognition.location}'),
            ],
            if (recognition.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: recognition.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could navigate to more details or save to favorites
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar with better context safety
  void _showErrorSnackBar(BuildContext context, String message) {
    // Multiple layers of safety checks
    try {
      if (!context.mounted) {
        if (kDebugMode) {
          print('⚠️ Context not mounted, skipping snackbar: $message');
        }
        return;
      }

      // Additional check for widget state
      final scaffold = context.findAncestorStateOfType<ScaffoldState>();
      if (scaffold == null) {
        if (kDebugMode) {
          print('⚠️ No Scaffold found, skipping snackbar: $message');
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing snackbar: $e');
        print('📝 Message was: $message');
      }
    }
  }

  /// Process image for landmark recognition
  Future<LandmarkRecognition?> recognizeLandmark(String imagePath) async {
    try {
      if (kDebugMode) {
        print('🎯 Starting landmark recognition for: $imagePath');
      }

      if (!_isModelInitialized) {
        if (kDebugMode) {
          print('⚠️ Model not initialized, initializing now...');
        }
        await initializeModel();
      }

      if (!_isModelInitialized) {
        if (kDebugMode) {
          print('❌ Model not initialized for landmark recognition');
        }
        return null;
      }

      if (kDebugMode) {
        print('🔍 Processing image: $imagePath');
        print('📱 File exists: ${await File(imagePath).exists()}');
        print('📏 File size: ${await File(imagePath).length()} bytes');
      }

      // Use TensorFlow Lite service to recognize landmark
      final prediction =
          await _tfLiteService.recognizeLandmark(File(imagePath));

      if (kDebugMode) {
        print('🤖 TensorFlow prediction result: ${prediction?.landmarkName ?? 'null'}');
        print('📊 Confidence: ${prediction?.confidence ?? 'N/A'}');
      }

      if (prediction == null) {
        if (kDebugMode) {
          print('❌ No prediction returned from TensorFlow Lite service');
        }
        return null;
      }

      // Create LandmarkRecognition object
      final recognition = LandmarkRecognition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        landmarkName: prediction.landmarkName,
        description: _getDescription(prediction.landmarkName),
        confidence: prediction.confidence,
        recognizedAt: DateTime.now(),
        location: _getLocation(prediction.landmarkName),
        tags: _getTags(prediction.landmarkName),
      );

      // Add to recent recognitions
      addRecognition(recognition);

      return recognition;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error recognizing landmark: $e');
      }
      return null;
    }
  }

  /// Get description for a landmark
  String _getDescription(String landmarkName) {
    final descriptions = {
      'Eiffel Tower':
          'Iconic iron lattice tower in Paris, France, built by Gustave Eiffel in 1889.',
      'Statue of Liberty':
          'Symbol of freedom and democracy in New York Harbor, a gift from France to the United States.',
      'Big Ben':
          'Famous clock tower in London, England, officially known as Elizabeth Tower.',
      'Taj Mahal':
          'Magnificent marble mausoleum in Agra, India, built by emperor Shah Jahan.',
      'Sydney Opera House':
          'Distinctive performing arts venue in Sydney, Australia, known for its unique architecture.',
      'Great Wall of China':
          'Ancient fortification system in northern China, built to protect against invasions.',
      'Colosseum':
          'Ancient amphitheater in Rome, Italy, where gladiatorial contests were held.',
      'Machu Picchu':
          'Ancient Incan citadel in Peru, set high in the Andes Mountains.',
      'Christ the Redeemer':
          'Art Deco statue of Jesus Christ overlooking Rio de Janeiro, Brazil.',
      'Petra':
          'Archaeological site in Jordan, famous for its rock-cut architecture.',
      'Golden Gate Bridge':
          'Iconic suspension bridge connecting San Francisco to Marin County.',
      'Empire State Building':
          'Art Deco skyscraper in Manhattan, New York City.',
      'Tower Bridge':
          'Bascule and suspension bridge crossing the River Thames in London.',
      'Mount Rushmore':
          'Memorial featuring carved faces of four US presidents in South Dakota.',
      'Sagrada Familia':
          'Basilica in Barcelona, Spain, designed by architect Antoni Gaudí.',
    };

    return descriptions[landmarkName] ??
        'A notable landmark with historical and cultural significance.';
  }

  /// Get location for a landmark
  String _getLocation(String landmarkName) {
    final locations = {
      'Eiffel Tower': 'Paris, France',
      'Statue of Liberty': 'New York, USA',
      'Big Ben': 'London, England',
      'Taj Mahal': 'Agra, India',
      'Sydney Opera House': 'Sydney, Australia',
      'Great Wall of China': 'Northern China',
      'Colosseum': 'Rome, Italy',
      'Machu Picchu': 'Cusco Region, Peru',
      'Christ the Redeemer': 'Rio de Janeiro, Brazil',
      'Petra': 'Ma\'an, Jordan',
      'Golden Gate Bridge': 'San Francisco, USA',
      'Empire State Building': 'New York, USA',
      'Tower Bridge': 'London, England',
      'Mount Rushmore': 'South Dakota, USA',
      'Sagrada Familia': 'Barcelona, Spain',
    };

    return locations[landmarkName] ?? 'Unknown Location';
  }

  /// Get tags for a landmark
  List<String> _getTags(String landmarkName) {
    final tags = {
      'Eiffel Tower': [
        'Architecture',
        'Historic',
        'Tourist Attraction',
        'Iron Structure'
      ],
      'Statue of Liberty': ['Monument', 'Historic', 'Symbol', 'Freedom'],
      'Big Ben': ['Architecture', 'Clock Tower', 'Historic', 'Gothic Revival'],
      'Taj Mahal': ['Architecture', 'Mausoleum', 'UNESCO', 'Marble'],
      'Sydney Opera House': [
        'Architecture',
        'Modern',
        'Performing Arts',
        'Iconic'
      ],
      'Great Wall of China': ['Historic', 'Fortification', 'UNESCO', 'Ancient'],
      'Colosseum': ['Ancient', 'Architecture', 'Amphitheater', 'UNESCO'],
      'Machu Picchu': ['Ancient', 'Incan', 'Mountain', 'UNESCO'],
      'Christ the Redeemer': ['Religious', 'Art Deco', 'Monument', 'Mountain'],
      'Petra': ['Ancient', 'Archaeological', 'Rock-cut', 'UNESCO'],
      'Golden Gate Bridge': ['Bridge', 'Suspension', 'Engineering', 'Iconic'],
      'Empire State Building': [
        'Skyscraper',
        'Art Deco',
        'Historic',
        'Architecture'
      ],
      'Tower Bridge': ['Bridge', 'Victorian', 'Engineering', 'Historic'],
      'Mount Rushmore': ['Monument', 'Presidential', 'Sculpture', 'Mountain'],
      'Sagrada Familia': [
        'Religious',
        'Architecture',
        'Modernist',
        'Unfinished'
      ],
    };

    return tags[landmarkName] ?? ['Landmark', 'Historic'];
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
      // In a real implementation, this would navigate to recognition details
      // For now, this is a placeholder for navigation functionality
      if (kDebugMode) {
        print('🔍 Tapped recognition: ${recognition.landmarkName}');
      }
    }
  }

  /// Check if model is initialized
  bool get isModelInitialized => _isModelInitialized;

  /// Process image for recognition without UI context dependency
  Future<LandmarkRecognition?> processImageWithoutUI(String imagePath) async {
    try {
      if (kDebugMode) {
        print('🎯 Processing image without UI context: $imagePath');
      }

      final recognition = await recognizeLandmark(imagePath);
      
      if (recognition != null) {
        if (kDebugMode) {
          print('✅ Recognition completed successfully: ${recognition.landmarkName} (${(recognition.confidence * 100).toStringAsFixed(1)}%)');
        }
        // Add to recent recognitions
        addRecognition(recognition);
      } else {
        if (kDebugMode) {
          print('❌ Recognition failed - no result returned');
        }
      }

      return recognition;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in context-free image processing: $e');
      }
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _tfLiteService.dispose();
  }
}
