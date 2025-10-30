import 'package:flutter/material.dart';
import '../../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/landmark_recognition_service.dart';
import '../localWidgets/recognition_instructions.dart';
import '../localWidgets/camera_section.dart';
import '../localWidgets/recent_recognitions.dart';

/// Landmark Recognition page - identify landmarks from photos using TensorFlow Lite
class LandmarkRecognitionPage extends StatefulWidget {
  const LandmarkRecognitionPage({super.key});

  @override
  State<LandmarkRecognitionPage> createState() =>
      _LandmarkRecognitionPageState();
}

class _LandmarkRecognitionPageState extends State<LandmarkRecognitionPage> {
  final LandmarkRecognitionService _recognitionService =
      LandmarkRecognitionService();
  bool _isModelLoading = true;
  String _loadingMessage = 'Initializing AI model...';

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    setState(() {
      _isModelLoading = true;
      _loadingMessage = 'Loading Resources Please Wait...';
    });

    try {
      final success = await _recognitionService.initializeModel();

      setState(() {
        _isModelLoading = false;
        _loadingMessage = success
            ? 'Model ready for landmark recognition!'
            : 'Failed to load model. Basic features available.';
      });

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to initialize AI model. Some features may be limited.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isModelLoading = false;
        _loadingMessage = 'Error initializing model';
      });
    }
  }

  @override
  void dispose() {
    // Don't dispose the recognition service as it's a singleton
    // that should persist throughout the app lifecycle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentRecognitions = _recognitionService.getRecentRecognitions();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'AI Landmark Recognition',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Model status indicator
              if (_isModelLoading)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_loadingMessage)),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: _recognitionService.isModelInitialized
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _recognitionService.isModelInitialized
                              ? Icons.check_circle
                              : Icons.warning,
                          color: _recognitionService.isModelInitialized
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recognitionService.isModelInitialized
                                ? 'Ready to click'
                                : 'AI Model Unavailable - Using fallback mode',
                            style: TextStyle(
                              color: _recognitionService.isModelInitialized
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              RecognitionInstructions(
                title: _recognitionService.getInstructionsTitle(),
                subtitle: _recognitionService.getInstructionsSubtitle(),
              ),
              const SizedBox(height: 24),
              CameraSection(
                onCameraPressed: () =>
                    _recognitionService.showImageSourceDialog(context),
                isEnabled: !_isModelLoading,
              ),
              const SizedBox(height: 24),
              RecentRecognitions(
                recognitions: recentRecognitions,
                onRecognitionTap: (recognitionId) =>
                    _recognitionService.handleRecognitionTap(recognitionId),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 2),
    );
  }
}
