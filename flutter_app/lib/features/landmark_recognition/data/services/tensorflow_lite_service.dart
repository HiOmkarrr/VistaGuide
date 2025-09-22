import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

/// TensorFlow Lite service for landmark recognition
/// Implementation based on Google Landmarks Classifier Asia v1 from Kaggle
/// Model: https://www.kaggle.com/models/google/landmarks/tfLite/classifier-asia-v1
class TensorFlowLiteService {
  static final TensorFlowLiteService _instance =
      TensorFlowLiteService._internal();
  factory TensorFlowLiteService() => _instance;
  TensorFlowLiteService._internal();

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;

  // Classification configuration (mimicking Kotlin Task Library implementation)
  double _scoreThreshold =
      0.5; // Equivalent to ImageClassifierOptions.setScoreThreshold
  int _maxResults = 1; // Equivalent to setMaxResults
  int _numThreads = 2; // Equivalent to BaseOptions.setNumThreads

  // Model configuration for Google Landmarks Classifier Asia v1
  static const String _modelPath = 'assets/models/1.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 321; // Google Landmarks model uses 321x321
  static const int _numChannels = 3; // RGB channels

  /// Initialize the TensorFlow Lite model
  Future<bool> initializeModel() async {
    try {
      if (kDebugMode) {
        print('🤖 Initializing TensorFlow Lite model...');
      }

      // Load the model with interpreter options (threads etc.)
      final interpreterOptions = InterpreterOptions()..threads = _numThreads;
      _interpreter =
          await Interpreter.fromAsset(_modelPath, options: interpreterOptions);

      if (_interpreter == null) {
        if (kDebugMode) {
          print('❌ Failed to load TensorFlow Lite model');
        }
        return false;
      }

      // Load labels if available
      await _loadLabels();

      // Get model input/output info
      _printModelInfo();

      _isModelLoaded = true;

      if (kDebugMode) {
        print('✅ TensorFlow Lite model initialized successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing TensorFlow Lite model: $e');
      }
      return false;
    }
  }

  /// Load labels from assets (if labels.txt exists)
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      if (kDebugMode) {
        print('📋 Loaded ${_labels?.length ?? 0} labels');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Labels file not found or error loading: $e');
      }
      // Create default labels for landmarks (common landmark categories)
      _labels = [
        'Eiffel Tower',
        'Statue of Liberty',
        'Big Ben',
        'Taj Mahal',
        'Sydney Opera House',
        'Great Wall of China',
        'Colosseum',
        'Machu Picchu',
        'Christ the Redeemer',
        'Petra',
        'Golden Gate Bridge',
        'Empire State Building',
        'Tower Bridge',
        'Mount Rushmore',
        'Sagrada Familia',
        'Other Landmark',
      ];
    }
  }

  /// Print model information for debugging
  void _printModelInfo() {
    if (_interpreter == null) return;

    final inputTensors = _interpreter!.getInputTensors();
    final outputTensors = _interpreter!.getOutputTensors();

    if (kDebugMode) {
      print('📊 Model Information:');
      print('   Input Tensors: ${inputTensors.length}');
      for (int i = 0; i < inputTensors.length; i++) {
        print(
            '     Input $i: ${inputTensors[i].shape} (${inputTensors[i].type})');
      }
      print('   Output Tensors: ${outputTensors.length}');
      for (int i = 0; i < outputTensors.length; i++) {
        print(
            '     Output $i: ${outputTensors[i].shape} (${outputTensors[i].type})');
      }
    }
  }

  /// Recognize landmark from image file
  Future<LandmarkPrediction?> recognizeLandmark(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      if (kDebugMode) {
        print('❌ TensorFlow: Model not loaded. Please initialize first.');
      }
      return null;
    }

    try {
      if (kDebugMode) {
        print('🔍 TensorFlow: Processing image for landmark recognition...');
        print('📁 TensorFlow: Image file: ${imageFile.path}');
        print('📏 TensorFlow: File exists: ${await imageFile.exists()}');
        if (await imageFile.exists()) {
          final fileSize = await imageFile.length();
          print('📊 TensorFlow: File size: $fileSize bytes');
        }
      }

      // Read and preprocess the image
      final imageBytes = await imageFile.readAsBytes();
      if (kDebugMode) {
        print('📸 TensorFlow: Image bytes length: ${imageBytes.length}');
      }

      final preprocessedImage = await _preprocessImage(imageBytes);

      if (preprocessedImage == null) {
        if (kDebugMode) {
          print('❌ TensorFlow: Failed to preprocess image');
        }
        return null;
      }

      if (kDebugMode) {
        print(
            '✅ TensorFlow: Image preprocessed successfully. Size: ${preprocessedImage.length}');
      }

      // Run inference
      final output = await _runInference(preprocessedImage);

      if (output == null) {
        if (kDebugMode) {
          print('❌ TensorFlow: Inference failed');
        }
        return null;
      }

      if (kDebugMode) {
        print(
            '✅ TensorFlow: Inference completed. Output length: ${output.length}');
      }

      // Process results
      final prediction = _processOutput(output);

      if (kDebugMode) {
        print('✅ TensorFlow: Landmark recognition completed');
        if (prediction != null) {
          print(
              '   🎯 TensorFlow: Predicted: ${prediction.landmarkName} (${(prediction.confidence * 100).toStringAsFixed(1)}%)');
        } else {
          print('   ❌ TensorFlow: No valid prediction generated');
        }
      }

      return prediction;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during landmark recognition: $e');
      }
      return null;
    }
  }

  /// Update runtime configuration (optional)
  void configure({double? scoreThreshold, int? maxResults, int? numThreads}) {
    if (scoreThreshold != null) {
      _scoreThreshold = scoreThreshold.clamp(0.0, 1.0);
    }
    if (maxResults != null && maxResults > 0) {
      _maxResults = maxResults;
    }
    if (numThreads != null && numThreads > 0) {
      _numThreads = numThreads;
    }
    if (kDebugMode) {
      print(
          '⚙️ Updated TFLite config => threshold: $_scoreThreshold, maxResults: $_maxResults, threads: $_numThreads');
    }
  }

  /// Preprocess image for Google Landmarks model (321x321, uint8)
  Future<Uint8List?> _preprocessImage(Uint8List imageBytes) async {
    try {
      if (kDebugMode) {
        print('🖼️ TensorFlow: Starting image preprocessing...');
      }

      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        if (kDebugMode) {
          print('❌ TensorFlow: Failed to decode image');
        }
        return null;
      }

      if (kDebugMode) {
        print(
            '📏 TensorFlow: Original image size: ${image.width}x${image.height}');
      }

      // Resize to model input size (321x321 for Google Landmarks)
      img.Image resizedImage =
          img.copyResize(image, width: _inputSize, height: _inputSize);

      if (kDebugMode) {
        print(
            '📐 TensorFlow: Resized to: ${resizedImage.width}x${resizedImage.height}');
      }

      // Convert to Uint8List (RGB format) as expected by the model
      final Uint8List input = Uint8List(_inputSize * _inputSize * _numChannels);

      int pixelIndex = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);

          // Extract RGB values as uint8 (0-255 range)
          input[pixelIndex++] = img.getRed(pixel);
          input[pixelIndex++] = img.getGreen(pixel);
          input[pixelIndex++] = img.getBlue(pixel);
        }
      }

      if (kDebugMode) {
        print(
            '✅ TensorFlow: Preprocessing completed, output size: ${input.length}');
      }

      return input;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error preprocessing image: $e');
      }
      return null;
    }
  }

  /// Run model inference
  Future<List<double>?> _runInference(Uint8List input) async {
    try {
      if (kDebugMode) {
        print('🧠 TensorFlow: Starting inference...');
        print('📊 TensorFlow: Input size: ${input.length}');
      }

      // Prepare input tensor (batch_size=1, height=321, width=321, channels=3)
      final inputTensor =
          input.reshape([1, _inputSize, _inputSize, _numChannels]);

      if (kDebugMode) {
        print(
            '📈 TensorFlow: Input tensor shape: [1, $_inputSize, $_inputSize, $_numChannels]');
      }

      // Get output tensor info
      final outputTensors = _interpreter!.getOutputTensors();
      final outputShape = outputTensors[0].shape;
      final outputSize = outputShape.reduce((a, b) => a * b);

      if (kDebugMode) {
        print('📉 TensorFlow: Output tensor shape: $outputShape');
        print('📊 TensorFlow: Output size: $outputSize');
      }

      // Prepare output tensor
      final outputTensor =
          List.filled(outputSize, 0.0).reshape([1, outputSize]);

      // Run inference
      if (kDebugMode) {
        print('⚡ TensorFlow: Running model inference...');
      }

      _interpreter!.run(inputTensor, outputTensor);

      // Extract output
      final output = outputTensor[0].cast<double>();

      if (kDebugMode) {
        print('✅ TensorFlow: Inference completed successfully');
        print('📊 TensorFlow: Output values count: ${output.length}');

        // Show top 5 confidence values for debugging
        final sortedWithIndices = <MapEntry<int, double>>[];
        for (int i = 0; i < output.length; i++) {
          sortedWithIndices.add(MapEntry(i, output[i]));
        }
        sortedWithIndices.sort((a, b) => b.value.compareTo(a.value));

        print('🏆 TensorFlow: Top 5 predictions:');
        for (int i = 0; i < 5 && i < sortedWithIndices.length; i++) {
          final entry = sortedWithIndices[i];
          print(
              '   ${i + 1}. Index ${entry.key}: ${(entry.value * 100).toStringAsFixed(2)}%');
        }
      }

      return output;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during inference: $e');
      }
      return null;
    }
  }

  /// Process model output to get prediction (mimics ImageClassifier behavior)
  LandmarkPrediction? _processOutput(List<double> output) {
    if (_labels == null || _labels!.isEmpty) {
      if (kDebugMode) print('❌ No labels loaded, cannot classify');
      return null;
    }

    final labelsCount = _labels!.length;
    final outLen = output.length;

    if (kDebugMode) {
      print(
          '📦 Parsing output: length=$outLen labels=$labelsCount threshold=$_scoreThreshold maxResults=$_maxResults');
    }

    // CASE A: Perfect match -> standard classification path
    if (outLen == labelsCount) {
      final stats = _analyzeOutput(output, labelsCount);
      List<double> scores;
      if (stats['treatAsProbabilities'] == true) {
        scores = output;
        if (kDebugMode) {
          print(
              '🧪 Treating outputs as probability distribution (sum≈${stats['sum'].toStringAsFixed(3)})');
        }
      } else {
        scores = _applySoftmax(output);
        if (kDebugMode) {
          print(
              '🧪 Applied softmax to logits (preSum=${stats['sum'].toStringAsFixed(3)})');
        }
      }
      return _selectTopWithLabels(scores);
    }

    // CASE B: Output length massively larger than labels -> model & labels mismatch.
    // Example: output=98960, labels=273. This likely means: Using a global classifier (~100k classes)
    // while only having a small subset label file. We will:
    //  1. Compute statistics on whole output
    //  2. Treat values in [0,1] as independent multi-label sigmoid probabilities (DO NOT softmax)
    //  3. Select top-K above threshold across FULL vector (not just first labelsCount)
    //  4. Map indices < labelsCount to known labels; others => 'Class <index>' placeholder
    //  5. If nothing passes threshold, progressively lower threshold (0.5 -> 0.3 -> 0.1) or pick absolute top.

    final double minVal = output.reduce(math.min);
    final double maxVal = output.reduce(math.max);
    double sumSample = 0;
    int sampleCount = math.min(2000, outLen);
    for (int i = 0; i < sampleCount; i++) {
      sumSample += output[i];
    }
    final double meanSample = sumSample / sampleCount;
    int abovePoint5 = 0;
    int abovePoint9 = 0;
    for (int i = 0; i < outLen; i++) {
      final v = output[i];
      if (v >= 0.5) abovePoint5++;
      if (v >= 0.9) abovePoint9++;
    }
    if (kDebugMode) {
      print(
          '🔬 Large output mismatch detected. Stats over all $outLen values:');
      print(
          '   min=$minVal max=$maxVal sampleMean≈${meanSample.toStringAsFixed(4)}');
      print(
          '   >=0.5: $abovePoint5  ( ${(abovePoint5 / outLen * 100).toStringAsFixed(2)}% )');
      print(
          '   >=0.9: $abovePoint9  ( ${(abovePoint9 / outLen * 100).toStringAsFixed(2)}% )');
      print(
          '⚠️ Labels file likely does not match model. Provide full labels file with $outLen lines for proper mapping.');
    }

    // Multi-label selection across entire vector
    List<_IndexedScore> topEntries = _topK(output, math.max(_maxResults, 5));

    // Filter by dynamic thresholds
    double dynamicThreshold = _scoreThreshold;
    List<_IndexedScore> filtered =
        topEntries.where((e) => e.score >= dynamicThreshold).toList();
    if (filtered.isEmpty && dynamicThreshold > 0.3) {
      dynamicThreshold = 0.3;
      filtered = topEntries.where((e) => e.score >= dynamicThreshold).toList();
    }
    if (filtered.isEmpty && dynamicThreshold > 0.1) {
      dynamicThreshold = 0.1;
      filtered = topEntries.where((e) => e.score >= dynamicThreshold).toList();
    }
    if (filtered.isEmpty) {
      // Fallback: accept very top result even if below thresholds
      filtered = [topEntries.first];
      if (kDebugMode) {
        print(
            '🛟 No predictions passed thresholds (0.5/0.3/0.1). Using absolute top result.');
      }
    }

    // Trim to requested maxResults
    filtered.sort((a, b) => b.score.compareTo(a.score));
    final chosen = filtered.take(_maxResults).toList();

    // Build structured predictions (limit 5 for UI preview)
    final preview = filtered.take(5).map((e) {
      final label =
          e.index < labelsCount ? _labels![e.index] : 'Class ${e.index}';
      return LandmarkConfidence(landmarkName: label, confidence: e.score);
    }).toList();

    final best = chosen.first;
    final bestLabel =
        best.index < labelsCount ? _labels![best.index] : 'Class ${best.index}';

    if (kDebugMode) {
      print(
          '�️ Multi-label top (dynamicThreshold=$dynamicThreshold requestedThreshold=$_scoreThreshold):');
      for (int i = 0; i < preview.length; i++) {
        final p = preview[i];
        print(
            '   ${i + 1}. ${p.landmarkName} ${(p.confidence * 100).toStringAsFixed(2)}% (idx=${filtered[i].index})');
      }
    }

    return LandmarkPrediction(
      landmarkName: bestLabel,
      confidence: best.score,
      allPredictions: preview,
    );
  }

  Map<String, dynamic> _analyzeOutput(List<double> output, int labelsCount) {
    // Analyze first labelsCount values
    final slice = output.take(labelsCount).toList();
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    double sum = 0;
    bool allNonNegative = true;
    for (final v in slice) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
      sum += v;
      if (v < 0) allNonNegative = false;
    }
    final treatAsProbabilities = allNonNegative && (sum > 0.95 && sum < 1.05);
    return {
      'min': minVal,
      'max': maxVal,
      'sum': sum,
      'treatAsProbabilities': treatAsProbabilities,
    };
  }

  /// Apply softmax to output for proper probability distribution
  List<double> _applySoftmax(List<double> input) {
    final maxVal = input.reduce((a, b) => a > b ? a : b);
    final exp = input.map((x) => math.exp(x - maxVal)).toList();
    final sum = exp.reduce((a, b) => a + b);
    return exp.map((x) => x / sum).toList();
  }

  /// Select top predictions when output length == labels length (standard classification)
  LandmarkPrediction _selectTopWithLabels(List<double> scores) {
    final List<_IndexedScore> entries = [];
    for (int i = 0; i < scores.length; i++) {
      final s = scores[i];
      if (s >= _scoreThreshold && !s.isNaN && s.isFinite) {
        entries.add(_IndexedScore(i, s));
      }
    }
    if (entries.isEmpty) {
      // fallback: pick absolute best
      double bestVal = -1;
      int bestIdx = -1;
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > bestVal) {
          bestVal = scores[i];
          bestIdx = i;
        }
      }
      if (kDebugMode) {
        print(
            '🛟 No scores >= threshold $_scoreThreshold; using best index $bestIdx (${(bestVal * 100).toStringAsFixed(2)}%)');
      }
      final bestLabel =
          bestIdx < _labels!.length ? _labels![bestIdx] : 'Class $bestIdx';
      return LandmarkPrediction(
        landmarkName: bestLabel,
        confidence: bestVal,
        allPredictions: [
          LandmarkConfidence(landmarkName: bestLabel, confidence: bestVal)
        ],
      );
    }
    entries.sort((a, b) => b.score.compareTo(a.score));
    final top = entries.take(_maxResults).toList();
    final preview = entries
        .take(5)
        .map((e) => LandmarkConfidence(
              landmarkName: _labels![e.index],
              confidence: e.score,
            ))
        .toList();
    final best = top.first;
    return LandmarkPrediction(
      landmarkName: _labels![best.index],
      confidence: best.score,
      allPredictions: preview,
    );
  }

  /// Efficient partial top-K selection without sorting entire 100k vector
  List<_IndexedScore> _topK(List<double> values, int k) {
    if (k <= 0) return [];
    // Simple approach: maintain list sorted ascending by score with max size k
    final List<_IndexedScore> heap = [];
    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      if (v.isNaN || !v.isFinite) continue;
      if (heap.length < k) {
        heap.add(_IndexedScore(i, v));
        heap.sort((a, b) => a.score.compareTo(b.score));
      } else if (v > heap.first.score) {
        heap[0] = _IndexedScore(i, v);
        heap.sort((a, b) => a.score.compareTo(b.score));
      }
    }
    // Return descending order
    heap.sort((a, b) => b.score.compareTo(a.score));
    return heap;
  }

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Get available labels
  List<String>? get availableLabels => _labels;

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;

    if (kDebugMode) {
      print('🧹 TensorFlow Lite service disposed');
    }
  }
}

/// Internal struct for sorting scores (outside service class)
class _IndexedScore {
  final int index;
  final double score;
  _IndexedScore(this.index, this.score);
}

/// Landmark prediction result
class LandmarkPrediction {
  final String landmarkName;
  final double confidence;
  final List<LandmarkConfidence> allPredictions;

  LandmarkPrediction({
    required this.landmarkName,
    required this.confidence,
    required this.allPredictions,
  });
}

/// Individual landmark confidence score
class LandmarkConfidence {
  final String landmarkName;
  final double confidence;

  LandmarkConfidence({
    required this.landmarkName,
    required this.confidence,
  });
}
