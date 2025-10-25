import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/landmark_recognition.dart';
import 'hybrid_recognition_service.dart';
import '../../presentation/localWidgets/landmark_result_widget.dart';
import '../../presentation/pages/landmark_chatbot_page.dart';

/// Service to manage landmark recognition functionality
class LandmarkRecognitionService {
  static final LandmarkRecognitionService _instance =
      LandmarkRecognitionService._internal();
  factory LandmarkRecognitionService() => _instance;
  LandmarkRecognitionService._internal();

  final HybridLandmarkRecognitionService _hybridService = 
      HybridLandmarkRecognitionService();
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

  /// Initialize the Hybrid Recognition Model
  /// 
  /// Loads CSV data, embedding model, prototypes, and LLM
  Future<bool> initializeModel() async {
    if (_isModelInitialized) return true;

    try {
      if (kDebugMode) {
        print('🚀 Initializing hybrid landmark recognition model...');
      }

      // Initialize the hybrid service
      final success = await _hybridService.initialize();

      _isModelInitialized = success;

      if (_isModelInitialized) {
        if (kDebugMode) {
          print('✅ Hybrid recognition model initialized successfully');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to initialize hybrid recognition model');
        }
      }

      return _isModelInitialized;
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
    return 'Point your camera at a landmark to identify it.';
  }

  /// Handle camera button press - directly opens camera
  Future<void> showImageSourceDialog(BuildContext context) async {
    if (kDebugMode) {
      print('📱 Camera button pressed - opening camera directly');
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

    // Directly open camera (no dialog)
    await _pickImageFromCamera(context);
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
        print(
            '📱 Camera picker result: ${image != null ? "Image captured: ${image.path}" : "No image captured (cancelled?)"}');
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
      // Safely dismiss any open dialogs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            // Try to pop any open dialogs
            Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
          } catch (navError) {
            if (kDebugMode) {
              print('⚠️ Could not dismiss dialogs: $navError');
            }
          }
        }
      });
    }
  }

  /// Process the selected image
  Future<void> _processSelectedImage(
      BuildContext context, File imageFile) async {
    // Check if context is still mounted before showing dialog
    if (!context.mounted) return;

    // Show loading dialog using root navigator for go_router compatibility
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => const AlertDialog(
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
        print(
            '🔮 Recognition completed. Result: ${prediction?.landmarkName ?? 'null'}');
      }

      // Dismiss loading dialog safely FIRST
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not dismiss loading dialog: $e');
          }
        }
      }

      if (prediction != null) {
        if (kDebugMode) {
          print('✅ Showing results for: ${prediction.landmarkName}');
        }
        // Show results dialog with imageFile
        // Use addPostFrameCallback to ensure safe navigation after dialog dismissal
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showRecognitionResults(context, prediction, imageFile);
          }
        });
      } else {
        if (kDebugMode) {
          print('❌ No prediction result, showing error');
        }
        if (context.mounted) {
          _showNoMatchDialog(context);
        }
      }
    } catch (e) {
      // Dismiss loading dialog safely
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (navError) {
          if (kDebugMode) {
            print('⚠️ Could not dismiss loading dialog: $navError');
          }
        }
      }

      if (kDebugMode) {
        print('❌ Error processing image: $e');
      }

      if (context.mounted) {
        _showErrorSnackBar(context, 'Error processing image');
      }
    }
  }

  /// Show recognition results using the custom result widget
  void _showRecognitionResults(
      BuildContext context, LandmarkRecognition recognition, File imageFile) {
    // Check if context is still mounted before showing dialog
    if (!context.mounted) return;

    // Extract landmark ID from recognition
    final landmarkId = int.tryParse(recognition.id) ?? 0;

    showLandmarkResultDialog(
      context: context,
      imageFile: imageFile,
      recognition: recognition,
      onLearnMore: () {
        // For go_router, we need to get the root navigator context
        // Close dialog using root navigator to avoid go_router conflicts
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
        
        // Navigate to chatbot page after a short delay
        Future.delayed(const Duration(milliseconds: 150), () {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => LandmarkChatbotPage(
                  recognition: recognition,
                  landmarkId: landmarkId,
                ),
              ),
            );
          }
        });
      },
    );
  }

  /// Show dialog when no landmark match is found
  void _showNoMatchDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      useRootNavigator: true, // Use root navigator for go_router compatibility
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('No Match Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not recognize a landmark in this image.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'This could happen if:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTipItem('• The image doesn\'t contain a clear view of a landmark'),
            _buildTipItem('• The landmark is not in our database'),
            _buildTipItem('• The image quality is too low'),
            _buildTipItem('• The landmark is partially obstructed'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Try capturing a clearer photo of the landmark from a better angle with enough zoom on the actual landmark.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context, rootNavigator: true);
              if (navigator.canPop()) {
                navigator.pop();
              }
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Helper to build tip items
  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
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

  /// Process image for landmark recognition using hybrid GPS + Image recognition
  /// 
  /// Uses HybridLandmarkRecognitionService to combine GPS and visual data
  Future<LandmarkRecognition?> recognizeLandmark(String imagePath) async {
    try {
      if (kDebugMode) {
        print('🔍 Starting hybrid landmark recognition...');
        print('📸 Image path: $imagePath');
      }

      // Run hybrid recognition with File object
      final result = await _hybridService.recognizeLandmark(File(imagePath));

      if (!result.success) {
        if (kDebugMode) {
          print('❌ No matching landmark found');
        }
        return null;
      }

      // Convert RecognitionResult to LandmarkRecognition model
      final recognition = LandmarkRecognition(
        id: result.landmarkId?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        landmarkName: result.landmarkName,
        description: result.landmarkInfo,
        confidence: result.confidenceScore,
        recognizedAt: DateTime.now(),
        location: 'India', // Can enhance with city/state from landmark data
        tags: [
          'Confidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%',
          if (result.visualScore != null) 'Visual: ${(result.visualScore! * 100).toStringAsFixed(1)}%',
          if (result.gpsScore != null && result.gpsScore! > 0) 'GPS: ${(result.gpsScore! * 100).toStringAsFixed(1)}%',
          if (result.bonusApplied) 'GPS+Visual Match ✓',
        ],
      );

      // Add to recent recognitions
      addRecognition(recognition);

      if (kDebugMode) {
        print('✅ Recognition complete: ${recognition.landmarkName}');
        print('📊 Confidence: ${(recognition.confidence * 100).toStringAsFixed(1)}%');
      }

      return recognition;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error recognizing landmark: $e');
      }
      return null;
    }
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
          print(
              '✅ Recognition completed successfully: ${recognition.landmarkName} (${(recognition.confidence * 100).toStringAsFixed(1)}%)');
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
    _hybridService.dispose();
  }
}
