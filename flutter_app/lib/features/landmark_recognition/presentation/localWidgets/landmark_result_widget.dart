import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/landmark_recognition.dart';

/// Widget to display landmark recognition results
/// Shows the captured image, landmark name, description, and confidence scores
class LandmarkResultWidget extends StatelessWidget {
  final File? imageFile;
  final LandmarkRecognition recognition;
  final VoidCallback? onClose;
  final VoidCallback? onLearnMore;

  const LandmarkResultWidget({
    super.key,
    this.imageFile,
    required this.recognition,
    this.onClose,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            if (imageFile != null) _buildImageSection(),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Landmark Name
                  Text(
                    recognition.landmarkName.replaceAll('_', ' '),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Confidence Score - Large Display
                  _buildConfidenceDisplay(context),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onClose ?? () {
                            final navigator = Navigator.of(context, rootNavigator: true);
                            if (navigator.canPop()) {
                              navigator.pop();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onLearnMore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Learn More'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the image section at the top
  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.file(
          imageFile!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Build large confidence display
  Widget _buildConfidenceDisplay(BuildContext context) {
    final confidence = recognition.confidence;
    final confidencePercent = (confidence * 100).round();
    
    Color confidenceColor;
    String confidenceText;
    
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
      confidenceText = 'Very Confident';
    } else if (confidence >= 0.6) {
      confidenceColor = Colors.orange;
      confidenceText = 'Confident';
    } else if (confidence >= 0.4) {
      confidenceColor = Colors.deepOrange;
      confidenceText = 'Moderately Confident';
    } else {
      confidenceColor = Colors.red;
      confidenceText = 'Low Confidence';
    }

    return Column(
      children: [
        // Large percentage display
        Text(
          '$confidencePercent%',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: confidenceColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        // Confidence text
        Text(
          confidenceText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: confidenceColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

/// Dialog function for easy display
Future<void> showLandmarkResultDialog({
  required BuildContext context,
  File? imageFile,
  required LandmarkRecognition recognition,
  VoidCallback? onLearnMore,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true, // Use root navigator for go_router compatibility
    builder: (context) => LandmarkResultWidget(
      imageFile: imageFile,
      recognition: recognition,
      onLearnMore: onLearnMore,
    ),
  );
}
