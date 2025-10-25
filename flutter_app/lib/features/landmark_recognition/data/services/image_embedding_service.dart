import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service for generating image embeddings using the model_int8.tflite model
class ImageEmbeddingService {
  static final ImageEmbeddingService _instance = ImageEmbeddingService._internal();
  factory ImageEmbeddingService() => _instance;
  ImageEmbeddingService._internal();

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  /// Initialize the embedding model
  Future<bool> initializeModel() async {
    if (_isModelLoaded) {
      if (kDebugMode) print('✅ Embedding model already loaded');
      return true;
    }

    try {
      if (kDebugMode) {
        print('🔄 Loading image embedding model (model_int8.tflite)...');
      }

      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_int8.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      
      if (_interpreter == null) {
        if (kDebugMode) print('❌ Interpreter is null after loading!');
        return false;
      }
      
      _isModelLoaded = true;

      if (kDebugMode) {
        print('✅ Image embedding model loaded successfully');
        final inputTensors = _interpreter!.getInputTensors();
        final outputTensors = _interpreter!.getOutputTensors();
        print('📊 Input shape: ${inputTensors[0].shape}');
        print('📊 Output shape: ${outputTensors[0].shape}');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error loading embedding model: $e');
        print('📍 Stack trace: $stackTrace');
        print('💡 Ensure model_int8.tflite exists in assets/models/');
      }
      _isModelLoaded = false;
      return false;
    }
  }

  /// Generate embedding features for an image
  Future<List<double>?> generateEmbedding(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      if (kDebugMode) {
        print('❌ Embedding model not loaded');
      }
      return null;
    }

    try {
      // Read and resize image to 256x256
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        if (kDebugMode) {
          print('❌ Failed to decode image');
        }
        return null;
      }

      // Resize to 256x256 as specified
      final resizedImage = img.copyResize(image, width: 256, height: 256);

      // Prepare input tensor
      final inputShape = _interpreter!.getInputTensors()[0].shape;
      final input = _imageToByteListFloat32(resizedImage, inputShape);

      // Prepare output tensor
      final outputShape = _interpreter!.getOutputTensors()[0].shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape(outputShape);

      // Run inference
      _interpreter!.run(input, output);

      // Extract features
      final features = (output[0] as List).cast<double>();

      if (kDebugMode) {
        print('✅ Generated embedding with ${features.length} features');
      }

      return features;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating embedding: $e');
      }
      return null;
    }
  }

  /// Convert image to Float32 byte list for model input
  Uint8List _imageToByteListFloat32(img.Image image, List<int> inputShape) {
    final height = inputShape[1];
    final width = inputShape[2];
    final channels = inputShape[3];

    final convertedBytes = Float32List(1 * height * width * channels);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        final pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel) / 255.0;
        buffer[pixelIndex++] = img.getGreen(pixel) / 255.0;
        buffer[pixelIndex++] = img.getBlue(pixel) / 255.0;
      }
    }

    return convertedBytes.buffer.asUint8List();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
